library(reshape2)
library(tidyr)
library(dplyr)
library(scales)
library(grid)
library(timeDate)
library(bizdays)
library(ggplot2)
library(Cairo)

#Start with Leaf maps

leafData <- read.csv("~/Documents/LeafRadar/mapStatuses.csv")
leafData <- leafData[,-which(names(leafData) == "District")]
leafData <- leafData %>% dcast(Time.Stamp ~ Area,value.var="Status")
leafData$Time.Stamp <- as.POSIXct(leafData$Time.Stamp,
                                  origin = "1970-01-01",
                                  tz="America/Chicago")

# Remove consecutive duplicate entries (ignoring differences in timestamp)
#  Done by using a slick hack with rowMeans and booleans. Essentially,
#  the first row is demanded with c(TRUE,...), and all other rows are 
#  compared to their subsequent neighbor (ignoring the first column)
#  and if there are any differences between the neighbors, this row is
#  also kept. Otherwise, it is dropped. To apply this trick, all NA 
#  values must be temporarily switched out with "NA" placeholders, and
#  reverted to NA values afterward.

leafData[is.na(leafData)] <- "NA"
leafData <- leafData[c(TRUE,rowMeans(tail(leafData[,-1],-1) != head(leafData[,-1],-1))>0),]

timeStamp <- leafData$Time.Stamp
leafData <- leafData[,-1]

# In Areas where a "Next" is followed by a "Done", change that 
#  "Next" to "Current". (Happens rarely, but confuses the model)
leafData[rbind("Done",head(leafData,-1))=="Next" & leafData=="Done"] <- "Current"

# Cut off each run of consecutive "Current" statuses to a max of 3 in a row
#  (Happens all too frequently in Brush pickup)
conseq <- function(vec) { 
  vec * ave(vec,c(0L, cumsum(diff(vec) != 0)),FUN = seq_along) 
}
currentStreakLength <- apply(leafData=="Current",2,conseq)
leafData[currentStreakLength>3] <- "Done"

# Add a new category, "Recently Done", that fills two rows after any
#  "Current" status is observed.
firstTwoEntriesAfterCurrent <- (rbind("Done",head(leafData,-1))=="Current" | rbind("Done","Done",head(leafData,-2))=="Current") & leafData!="Current"
leafData[firstTwoEntriesAfterCurrent] <- "Recently Done"
leafData <- cbind(Time.Stamp = timeStamp, leafData)

generateLeafModelData <- function(leafDataSideOfTown,targetArea) {
  
  # Select only the columns for Area Statuses
  leafDataStatuses <- leafDataSideOfTown %>%
    select(matches("Area[0-9]+_[0-9]+$"))
  
  # Drop any rows that lack "Current" status
  rowsWithCurrent <- rowSums(leafDataStatuses=="Current")>0
  leafDataStatuses <- leafDataStatuses[rowsWithCurrent,]
  
  # Grab the time stamp column
  timeStamp      <- leafDataSideOfTown[rowsWithCurrent,"Time.Stamp"]
  
  # Rearrange data.frame so that target area is last column
  #  Column order is otherwise unchanged. ("Cut the deck")
  targetAreaCol <- which(colnames(leafDataStatuses) %in% targetArea)
  nextColNum <- (targetAreaCol)%%ncol(leafDataStatuses)+1
  lastColNum <- ncol(leafDataStatuses)
  if (targetAreaCol != lastColNum) {
    leafDataStatuses <- leafDataStatuses[,c(nextColNum:lastColNum,1:targetAreaCol)]
  }
  
  # Find column number of last "Current" status
  rightmostCurrentCol <- function(x) {
    tail(colnames(leafDataStatuses)[x=="Current"],1)
  }
  rightmostCurrentColName <- apply(leafDataStatuses,1,rightmostCurrentCol)
  nColsFromCurrent <- lastColNum-match(rightmostCurrentColName,colnames(leafDataStatuses))
  
  # Find column number of first "Next" status, for use in case of "Recently Done"
  leftmostDoneOrNextCol <- function(x) {
    head(colnames(leafDataStatuses)[x=="Next" | x=="Done"],1)
  }
  leftmostDoneOrNextColName <- apply(leafDataStatuses,1,leftmostDoneOrNextCol)
  nColsReplacementValue <- ncol(leafDataStatuses)-match(leftmostDoneOrNextColName,colnames(leafDataStatuses))
  nColsFromCurrent <- ifelse(nColsFromCurrent < 30 & leafDataStatuses[,targetArea]=="Recently Done", 
                             nColsReplacementValue,
                             nColsFromCurrent)
  
  #   # Mask out data from after last pickup of the year
  #   #  (nDaysTilPickup is not a meaningful number here)
  #   rcumsum <- function(vec) {
  #     rev(cumsum(rev(vec)))
  #   }
  #   afterLastPickup <- rcumsum(as.numeric(leafDataStatuses[,targetArea]=="Current"))==0
  #   nDaysTilPickup <- nDaysTilPickup[!afterLastPickup]
  #   nColsFromCurrent <- nColsFromCurrent[!afterLastPickup]
  #   timeStamp      <- timeStamp[!afterLastPickup]
  
  # Build a data.frame with independent & dependent variables
  modelData <- data.frame(nColsFromCurrent)
  modelData$status <- factor(leafDataStatuses[,targetArea],levels=c("Done","Current","Next","Recently Done","Not Done"))
  modelData$nCurrent <- rowSums(leafDataStatuses=="Current")
  modelData$timeStamps <- timeStamp
  modelData$weekOfYear <- format(as.Date(modelData$timeStamps,format="%d-%m-%Y"),"%W")
  modelData$month <- format(as.Date(modelData$timeStamps,format="%d-%m-%Y"),"%m")
  
  modelData
}

#East
modelEastLeaf  <- readRDS("modelEastLeaf.rds")
leafDataEast <- leafData %>%
  select(-starts_with("Area02")) %>%
  select(-starts_with("Area04")) %>%
  select(-starts_with("Area06")) %>%
  select(-starts_with("Area08")) %>%
  select(-starts_with("Area10"))

#West
modelWestLeaf  <- readRDS("modelWestLeaf.rds")
leafDataWest <- leafData %>%
  select(-starts_with("Area01")) %>%
  select(-starts_with("Area03")) %>%
  select(-starts_with("Area05")) %>%
  select(-starts_with("Area07")) %>%
  select(-starts_with("Area09"))
for (sideOfTown in c("West","East")) {
  leafDataSideOfTown <- leafDataEast
  modelSideOfTown    <- modelEastLeaf
  if (sideOfTown == "West") {
    leafDataSideOfTown <- leafDataWest
    modelSideOfTown    <- modelWestLeaf
  }
  for (targetArea in colnames(leafDataSideOfTown[,-1])) {
    thisAreaModel <- cbind(Area=targetArea,generateLeafModelData(leafDataSideOfTown,targetArea))
    (pred.pred <- predict(modelSideOfTown,interval="prediction",newdata = thisAreaModel))
    mean <- tail(pred.pred[,"fit"],n=1)
    sd <- (tail(pred.pred[,"fit"],n=1)-tail(pred.pred[,"lwr"],n=1))/1.96
    
    # Build a list of business days going 60 days in either direction
    madisonHolidays <- c(holidayNYSE(2015),
                         holidayNYSE(2016),
                         timeDate("2015-11-27 05:00:00",
                                  format="%Y-%m-%d %H:%M:%S",
                                  FinCenter = "NewYork"),
                         timeDate("2016-11-25 05:00:00",
                                  format="%Y-%m-%d %H:%M:%S",
                                  FinCenter = "NewYork"))
    cal <- Calendar(madisonHolidays,weekdays = c("saturday","sunday"))
    today <- tail(thisAreaModel$timeStamps,n=1)
    bizDayList <- bizseq(today-60*24*60*60,today+60*24*60*60,cal)
    # Which day in this list is the latest day <= today?
    nToday <- tail(which(bizDayList<=as.Date(today)),n=1)
    bizDayListPretty <- format(bizDayList,"%a, %b %d")
    
    dataForBarChart <- data.frame(day=character(0),
                                  prob=numeric(0),
                                  prettyBizDays=character(0),
                                  stringsAsFactors = FALSE)
    numBarsDivTwo <- ceiling(qnorm(0.99)*sd)
    for (i in -numBarsDivTwo:numBarsDivTwo) {
      dataForBarChart[nrow(dataForBarChart)+1,] <- 
        c(paste0(round(mean,2),"+",i),
          pnorm(ceiling(mean)+i,mean=mean,sd=sd)-pnorm(floor(mean)+i,mean=mean,sd=sd),
          bizDayListPretty[nToday+floor(mean)+i])
    }
    
    dataForBarChart$day           <- factor(dataForBarChart$day,levels=rev(dataForBarChart$day))
    dataForBarChart$prettyBizDays <- factor(dataForBarChart$prettyBizDays,levels=rev(dataForBarChart$prettyBizDays))
    dataForBarChart$prob          <- as.numeric(dataForBarChart$prob)

#     # green bar-chart first    
#     green <- "#87B287"
#     g <- ggplot(data=dataForBarChart, aes(x=prettyBizDays, y=prob)) +
#       geom_bar(fill=green,colour=green,stat="identity")+
#       scale_y_continuous(labels=percent_format())+
#       coord_flip()+
#       xlab("")+ylab("")+ggtitle("Likely Pickup Days")+
#       theme(axis.text.x = element_text(vjust=0.5, size=12),
#             axis.ticks.x = element_line(colour = "white", size=0),
#             axis.ticks.y = element_line(colour = "white", size=0),
#             axis.text.y = element_text(colour="black",vjust=0.5, hjust=1, size=16, margin=margin(5,-15,10,5,"pt")),
#             panel.background = element_rect(fill="white"),
#             panel.grid.major.x = element_line(colour="#D0D0D0",size=.75),
#             panel.grid.major.y = element_line(colour="white"),
#             panel.grid.minor   = element_line(colour="white"),
#             plot.title = element_text(size=24,margin=margin(10,0,20,0,"pt")))
#     
#     dir <- substr(targetArea,0,6)
#     filename <- paste0(substring(targetArea,8),"_leaf.png")
#     CairoFonts("DejaVu Sans:style=Regular","DejaVu Sans:style=Bold","DejaVu Sans:style=Italic","DejaVu Sans:style=Bold Italic","Symbol")
#     CairoPNG(filename=paste(dir,filename,sep = "/"),width=600,height=480)
#     print(g)
#     dev.off()
    
    # grey-gold bar-chart next
    bkgdColor <- "#808080"
    barsColor <- "#fcd088"
    lineColor <- "#ffffff"
    textColor <- "#ffffff"
    gBarChart <- ggplot(data=dataForBarChart, aes(x=prettyBizDays, y=prob)) +
      geom_bar(fill=barsColor,colour=barsColor,stat="identity",width=0.8)+
      scale_y_continuous(labels=percent_format())+
      coord_flip()+
      xlab("")+ylab("")+ggtitle("")+
      theme(axis.text.x = element_text(vjust=0.5, size=12,color=textColor,margin=margin(0,0,-10,0,"pt")),
            axis.text.y = element_text(vjust=0.5, hjust=1, size=10, face="bold", color=textColor, margin=margin(5,-5,10,-10,"pt")),
            axis.ticks.x = element_line(colour = lineColor, size=0),
            axis.ticks.y = element_line(colour = lineColor, size=0),
            plot.background = element_rect(fill=bkgdColor),
            plot.margin = margin(-10,0,0,0,"pt"),
            panel.background = element_rect(fill=bkgdColor),
            panel.grid.major.x = element_line(colour=lineColor,size=.75),
            panel.grid.major.y = element_line(colour=bkgdColor),
            panel.grid.minor   = element_line(colour=bkgdColor))
    
    dir <- substr(targetArea,0,6)
    filename <- paste0(substring(targetArea,8),"_leaf_hist.png")
    CairoFonts("Josefin Sans:style=Regular","Josefin Sans:style=Bold","Josefin Sans:style=Italic","Josefin Sans:style=Bold Italic","Symbol")
    CairoPNG(filename=paste(dir,filename,sep = "/"),width=300,height=200)
    print(gBarChart)
    dev.off()
  }
}
# modelEastBrush <- readRDS("modelEastBrush.rds")
# modelWestBrush <- readRDS("modelWestBrush.rds")
# 
# leafData <- read.csv("~/Documents/LeafRadar/mapStatusesBrush.csv")
# leafData <- leafData[,-which(names(leafData) == "District")]
# leafData <- leafData %>% dcast(Time.Stamp ~ Area,value.var="Status")
# leafData$Time.Stamp <- as.POSIXct(leafData$Time.Stamp,
#                                   origin = "1970-01-01",
#                                   tz="America/Chicago")
# 
# # Remove consecutive duplicate entries (ignoring differences in timestamp)
# #  Done by using a slick hack with rowMeans and booleans. Essentially,
# #  the first row is demanded with c(TRUE,...), and all other rows are 
# #  compared to their subsequent neighbor (ignoring the first column)
# #  and if there are any differences between the neighbors, this row is
# #  also kept. Otherwise, it is dropped. To apply this trick, all NA 
# #  values must be temporarily switched out with "NA" placeholders, and
# #  reverted to NA values afterward.
# 
# leafData[is.na(leafData)] <- "NA"
# leafData <- leafData[c(TRUE,rowMeans(tail(leafData[,-1],-1) != head(leafData[,-1],-1))>0),]
# 
# timeStamp <- leafData$Time.Stamp
# leafData <- leafData[,-1]
# 
# # In Areas where a "Next" is followed by a "Done", change that 
# #  "Next" to "Current". (Happens rarely, but confuses the model)
# leafData[rbind("Done",head(leafData,-1))=="Next" & leafData=="Done"] <- "Current"
# 
# # Cut off each run of consecutive "Current" statuses to a max of 3 in a row
# #  (Happens all too frequently in Brush pickup)
# conseq <- function(vec) { 
#   vec * ave(vec,c(0L, cumsum(diff(vec) != 0)),FUN = seq_along) 
# }
# currentStreakLength <- apply(leafData=="Current",2,conseq)
# leafData[currentStreakLength>3] <- "Done"
# 
# # Add a new category, "Recently Done", that fills two rows after any
# #  "Current" status is observed.
# firstTwoEntriesAfterCurrent <- (rbind("Done",head(leafData,-1))=="Current" | rbind("Done","Done",head(leafData,-2))=="Current") & leafData!="Current"
# leafData[firstTwoEntriesAfterCurrent] <- "Recently Done"
# leafData <- cbind(Time.Stamp = timeStamp, leafData)
# 
# generateBrushModelData <- function(leafDataSideOfTown,targetArea) {
#   
#   # Select only the columns for Area Statuses
#   leafDataStatuses <- leafDataSideOfTown %>%
#     select(matches("Area[0-9]+_[0-9]+$"))
#   
#   # Drop any rows that lack "Current" status
#   rowsWithCurrent <- rowSums(leafDataStatuses=="Current")>0
#   leafDataStatuses <- leafDataStatuses[rowsWithCurrent,]
# 
#   # Grab the time stamp column
#   timeStamp      <- leafDataSideOfTown[rowsWithCurrent,"Time.Stamp"]
#   
#   # Rearrange data.frame so that target area is last column
#   #  Column order is otherwise unchanged. ("Cut the deck")
#   targetAreaCol <- which(colnames(leafDataStatuses) %in% targetArea)
#   nextColNum <- (targetAreaCol)%%ncol(leafDataStatuses)+1
#   lastColNum <- ncol(leafDataStatuses)
#   if (targetAreaCol != lastColNum) {
#     leafDataStatuses <- leafDataStatuses[,c(nextColNum:lastColNum,1:targetAreaCol)]
#   }
#   
#   # Find column number of last "Current" status
#   rightmostCurrentCol <- function(x) {
#     tail(colnames(leafDataStatuses)[x=="Current"],1)
#   }
#   rightmostCurrentColName <- apply(leafDataStatuses,1,rightmostCurrentCol)
#   nColsFromCurrent <- lastColNum-match(rightmostCurrentColName,colnames(leafDataStatuses))
#   
#   # Find column number of first "Next" status, for use in case of "Recently Done"
#   leftmostDoneOrNextCol <- function(x) {
#     head(colnames(leafDataStatuses)[x=="Next" | x=="Done"],1)
#   }
#   leftmostDoneOrNextColName <- apply(leafDataStatuses,1,leftmostDoneOrNextCol)
#   nColsReplacementValue <- ncol(leafDataStatuses)-match(leftmostDoneOrNextColName,colnames(leafDataStatuses))
#   nColsFromCurrent <- ifelse(nColsFromCurrent < 30 & leafDataStatuses[,targetArea]=="Recently Done", 
#                              nColsReplacementValue,
#                              nColsFromCurrent)
#   
# #   # Mask out data from after last pickup of the year
# #   #  (nDaysTilPickup is not a meaningful number here)
# #   rcumsum <- function(vec) {
# #     rev(cumsum(rev(vec)))
# #   }
# #   afterLastPickup <- rcumsum(as.numeric(leafDataStatuses[,targetArea]=="Current"))==0
# #   nDaysTilPickup <- nDaysTilPickup[!afterLastPickup]
# #   nColsFromCurrent <- nColsFromCurrent[!afterLastPickup]
# #   timeStamp      <- timeStamp[!afterLastPickup]
#   
#   # Build a data.frame with independent & dependent variables
#   modelData <- data.frame(nColsFromCurrent)
#   modelData$status <- factor(leafDataStatuses[,targetArea],levels=c("Done","Current","Next","Recently Done","Not Done"))
#   modelData$nCurrent <- rowSums(leafDataStatuses[,]=="Current")
#   modelData$timeStamps <- timeStamp
#   modelData$weekOfYear <- format(as.Date(modelData$timeStamps,format="%d-%m-%Y"),"%W")
#   modelData$month <- format(as.Date(modelData$timeStamps,format="%d-%m-%Y"),"%m")
#   
#   # Count how long each run of consecutive "Current"s is.
#   currentsInTargetArea <- leafDataStatuses[,targetArea]=="Current"
#   modelData$ageOfCurrentStatus <- currentsInTargetArea * ave(currentsInTargetArea, c(0L, cumsum(diff(currentsInTargetArea) != 0)),FUN = seq_along)
#   
#   # Allstreaks
#   allStreakLength <- apply(leafDataStatuses[,]=="Current",2,conseq)+
#     apply(leafDataStatuses[,]=="Done",2,conseq)+
#     apply(leafDataStatuses[,]=="Next",2,conseq)
#   modelData$ageOfStatus <- allStreakLength[,targetArea]
#   modelData$ageOfStatusSquared <- (modelData$ageOfStatus)^2
#   modelData$ageOfStatusGT10 <- modelData$ageOfStatus>10
#   
#   modelData
# }
# 
# #East
# modelEastBrush  <- readRDS("modelEastBrush.rds")
# brushDataEast <- leafData %>%
#   select(-starts_with("Area02")) %>%
#   select(-starts_with("Area04")) %>%
#   select(-starts_with("Area06")) %>%
#   select(-starts_with("Area08")) %>%
#   select(-starts_with("Area10"))
# 
# #West
# modelWestBrush  <- readRDS("modelWestBrush.rds")
# brushDataWest <- leafData %>%
#   select(-starts_with("Area01")) %>%
#   select(-starts_with("Area03")) %>%
#   select(-starts_with("Area05")) %>%
#   select(-starts_with("Area07")) %>%
#   select(-starts_with("Area09"))
# for (sideOfTown in c("West","East")) {
#   leafDataSideOfTown <- brushDataEast
#   modelSideOfTown    <- modelEastBrush
#   if (sideOfTown == "West") {
#     leafDataSideOfTown <- brushDataWest
#     modelSideOfTown    <- modelWestBrush
#   }
#   for (targetArea in colnames(leafDataSideOfTown[,-1])) {
#     thisAreaModel <- cbind(Area=targetArea,generateBrushModelData(leafDataSideOfTown,targetArea))
#     (pred.pred <- predict(modelSideOfTown,interval="prediction",newdata = thisAreaModel))
#     mean <- tail(pred.pred[,"fit"],n=1)
#     sd <- (tail(pred.pred[,"fit"],n=1)-tail(pred.pred[,"lwr"],n=1))/1.96
#     
#     # Build a list of business days going 60 days in either direction
#     madisonHolidays <- c(holidayNYSE(2015),
#                          holidayNYSE(2016),
#                          timeDate("2015-11-27 05:00:00",
#                                   format="%Y-%m-%d %H:%M:%S",
#                                   FinCenter = "NewYork"),
#                          timeDate("2016-11-25 05:00:00",
#                                   format="%Y-%m-%d %H:%M:%S",
#                                   FinCenter = "NewYork"))
#     cal <- Calendar(madisonHolidays,weekdays = c("saturday","sunday"))
#     today <- tail(thisAreaModel$timeStamps,n=1)
#     bizDayList <- bizseq(today-60*24*60*60,today+60*24*60*60,cal)
#     # Which day in this list is the latest day <= today?
#     nToday <- tail(which(bizDayList<=as.Date(today)),n=1)
#     bizDayListPretty <- format(bizDayList,"%a, %b %d")
#     
#     dataForBarChart <- data.frame(day=character(0),
#                                   prob=numeric(0),
#                                   prettyBizDays=character(0),
#                                   stringsAsFactors = FALSE)
#     numBarsDivTwo <- ceiling(qnorm(0.99)*sd)
#     for (i in -numBarsDivTwo:numBarsDivTwo) {
#       dataForBarChart[nrow(dataForBarChart)+1,] <- 
#         c(paste0(round(mean,2),"+",i),
#           pnorm(ceiling(mean)+i,mean=mean,sd=sd)-pnorm(floor(mean)+i,mean=mean,sd=sd),
#           bizDayListPretty[nToday+floor(mean)+i])
#     }
#     
#     dataForBarChart$day           <- factor(dataForBarChart$day,levels=rev(dataForBarChart$day))
#     dataForBarChart$prettyBizDays <- factor(dataForBarChart$prettyBizDays,levels=rev(dataForBarChart$prettyBizDays))
#     dataForBarChart$prob          <- as.numeric(dataForBarChart$prob)
#     
#     brown <- "#B28C87"
#     
#     g <- ggplot(data=dataForBarChart, aes(x=prettyBizDays, y=prob)) +
#       geom_bar(fill=brown,colour=brown,stat="identity")+
#       scale_y_continuous(labels=percent_format())+
#       coord_flip()+
#       xlab("")+ylab("")+ggtitle("Likely Pickup Days")+
#       theme(axis.text.x = element_text(vjust=0.5, size=12),
#             axis.ticks.x = element_line(colour = "white", size=0),
#             axis.ticks.y = element_line(colour = "white", size=0),
#             axis.text.y = element_text(colour="black",vjust=0.5, hjust=1, size=16, margin=margin(5,-15,10,5,"pt")),
#             panel.background = element_rect(fill="white"),
#             panel.grid.major.x = element_line(colour="#D0D0D0",size=.75),
#             panel.grid.major.y = element_line(colour="white"),
#             panel.grid.minor   = element_line(colour="white"),
#             plot.title = element_text(size=24,margin=margin(10,0,20,0,"pt")))
#     
#     dir <- substr(targetArea,0,6)
#     filename <- paste0(substring(targetArea,8),"_brush.png")
#     CairoFonts("DejaVu Sans:style=Regular","DejaVu Sans:style=Bold","DejaVu Sans:style=Italic","DejaVu Sans:style=Bold Italic","Symbol")
#     CairoPNG(filename=paste(dir,filename,sep = "/"),width=600,height=480)
#     print(g)
#     dev.off()
#   }
# }
