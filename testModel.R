library(reshape2)
library(tidyr)
library(dplyr)
library(FSA)
library(scales)
library(grid)
library(timeDate)
library(bizdays)
library(ggplot2)

model <- readRDS("model.rds")

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
# Add a new category, "Recently Done", that fills two rows after any
#  "Current" status is observed.
firstTwoEntriesAfterCurrent <- (rbind("Done",head(leafData,-1))=="Current" | rbind("Done","Done",head(leafData,-2))=="Current") & leafData!="Current"
leafData[firstTwoEntriesAfterCurrent] <- "Recently Done"
leafData <- cbind(Time.Stamp = timeStamp, leafData)

leafDataWest <- leafData %>%
  select(-starts_with("Area01")) %>%
  select(-starts_with("Area03")) %>%
  select(-starts_with("Area05")) %>%
  select(-starts_with("Area07")) %>%
  select(-starts_with("Area09"))

targetArea <- "Area02_001"
generateModelData <- function(leafDataWest,targetArea) {
  
  # Select only the columns for Area Statuses
  leafDataWestStatuses <- leafDataWest %>%
    select(matches("Area[0-9]+_[0-9]+$"))
  
  # Drop any rows that lack "Current" status
  rowsWithCurrent <- rowSums(leafDataWestStatuses=="Current")>0
  leafDataWestStatuses <- leafDataWestStatuses[rowsWithCurrent,]

  # Grab the time stamp column
  timeStamp      <- leafDataWest[rowsWithCurrent,"Time.Stamp"]
  
  # Rearrange data.frame so that target area is last column
  #  Column order is otherwise unchanged. ("Cut the deck")
  targetAreaCol <- which(colnames(leafDataWestStatuses) %in% targetArea)
  nextColNum <- (targetAreaCol)%%ncol(leafDataWestStatuses)+1
  lastColNum <- ncol(leafDataWestStatuses)
  if (targetAreaCol != lastColNum) {
    leafDataWestStatuses <- leafDataWestStatuses[,c(nextColNum:lastColNum,1:targetAreaCol)]
  }
  
  # Find column number of last "Current" status
  rightmostCurrentCol <- function(x) {
    tail(colnames(leafDataWestStatuses)[x=="Current"],1)
  }
  rightmostCurrentColName <- apply(leafDataWestStatuses,1,rightmostCurrentCol)
  nColsFromCurrent <- lastColNum-match(rightmostCurrentColName,colnames(leafDataWestStatuses))
  
  # Find column number of first "Next" status, for use in case of "Recently Done"
  leftmostDoneOrNextCol <- function(x) {
    head(colnames(leafDataWestStatuses)[x=="Next" | x=="Done"],1)
  }
  leftmostDoneOrNextColName <- apply(leafDataWestStatuses,1,leftmostDoneOrNextCol)
  nColsReplacementValue <- ncol(leafDataWestStatuses)-match(leftmostDoneOrNextColName,colnames(leafDataWestStatuses))
  nColsFromCurrent <- ifelse(nColsFromCurrent < 30 & leafDataWestStatuses[,targetArea]=="Recently Done", 
                             nColsReplacementValue,
                             nColsFromCurrent)
  
#   # Mask out data from after last pickup of the year
#   #  (nDaysTilPickup is not a meaningful number here)
#   afterLastPickup <- rcumsum(as.numeric(leafDataWestStatuses[,targetArea]=="Current"))==0
#   nDaysTilPickup <- nDaysTilPickup[!afterLastPickup]
#   nColsFromCurrent <- nColsFromCurrent[!afterLastPickup]
#   timeStamp      <- timeStamp[!afterLastPickup]
  
  # Build a data.frame with independent & dependent variables
  modelData <- data.frame(nColsFromCurrent)
  modelData$status <- factor(leafDataWestStatuses[,targetArea],levels=c("Done","Current","Next","Recently Done","Not Done"))
  modelData$nCurrent <- rowSums(leafDataWestStatuses[,]=="Current")
  modelData$timeStamps <- timeStamp
  modelData$weekOfYear <- format(as.Date(modelData$timeStamps,format="%d-%m-%Y"),"%W")
  modelData$month <- format(as.Date(modelData$timeStamps,format="%d-%m-%Y"),"%m")
  
  modelData
}

thisAreaModel <- cbind(Area=targetArea,generateModelData(leafDataWest,targetArea))
(pred.pred <- predict(model,interval="prediction",newdata = thisAreaModel))
mean <- tail(pred.pred[,"fit"],n=1)
sd <- (tail(pred.pred[,"fit"],n=1)-tail(pred.pred[,"lwr"],n=1))/1.96

# Build a list of business days going 60 days in either direction
madisonHolidays <- c(holidayNYSE(2016),timeDate("2015-11-25 05:00:00",format="%Y-%m-%d %H:%M:%S",FinCenter = "NewYork"))
cal <- Calendar(madisonHolidays,weekdays = c("saturday","sunday"))
today <- tail(thisAreaModel$timeStamps,n=1)
bizDayList <- bizseq(today-60*24*60*60,today+60*24*60*60,cal)
# Which day in this list == today?
nToday <- which(bizDayList==as.Date(today))
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

green <- "#87B287"

g <- ggplot(data=dataForBarChart, aes(x=prettyBizDays, y=prob)) +
  geom_bar(fill=green,colour=green,stat="identity")+
  scale_y_continuous(labels=percent_format())+
  coord_flip()+
  xlab("")+ylab("")+ggtitle("Likely Pickup Days")+
  theme(axis.text.x = element_text(vjust=0.5, size=12),
        axis.ticks.x = element_line(colour = "white"),
        axis.ticks.y = element_line(colour = "white"),
        axis.text.y = element_text(colour="black",vjust=0.5, hjust=1, size=16, margin=margin(5,-15,10,5,"pt")),
        panel.background = element_rect(fill="white"),
        panel.grid.major.x = element_line(colour="#D0D0D0",size=.75),
        panel.grid.major.y = element_line(colour="white"),
        panel.grid.minor   = element_line(colour="white"),
        plot.title = element_text(size=24,margin=margin(10,0,20,0,"pt")))
print(g)
