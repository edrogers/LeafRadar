library(reshape2)
library(tidyr)
library(dplyr)
library(FSA)

model <- readRDS("model.rds")

leafData <- read.csv("~/Documents/LeafRadar/mapStatuses.csv")
leafData <- leafData[,-which(names(leafData) == "District")]
leafData <- leafData %>% dcast(Time.Stamp ~ Area,value.var="Status")
leafData$Time.Stamp <- as.POSIXct(leafData$Time.Stamp,
                                  origin = "1970-01-01",
                                  tz="America/Chicago")
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

targetArea <- "Area04_012"
generateModelData <- function(leafDataWest,targetArea) {
  
  # Select only the columns for Area Statuses
  leafDataWestStatuses <- leafDataWest %>%
    select(matches("Area[0-9]+_[0-9]+$"))
  
  # Drop any rows that have 100% "Done" status
  rowsNotAllDone <- rowMeans(leafDataWestStatuses!="Done")>0
  leafDataWestStatuses <- leafDataWestStatuses[rowsNotAllDone,]

  # Grab the time stamp column
  timeStamp      <- leafDataWest[rowsNotAllDone,"Time.Stamp"]
  
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
predict(model,interval="prediction",newdata = thisAreaModel)
