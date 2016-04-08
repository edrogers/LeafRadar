library(reshape2)
library(tidyr)
library(dplyr)
library(FSA)

models <- readRDS("models.rds")

leafData <- read.csv("~/Documents/LeafRadar/currentStatus.csv")
leafData <- leafData[,-which(names(leafData) == "District")]
leafData <- leafData %>% dcast(Time.Stamp ~ Area,value.var="Status")
leafData$Time.Stamp <- as.POSIXct(leafData$Time.Stamp,
                                  origin = "1970-01-01",
                                  tz="America/Chicago")
# TimeStamps <- leafData$Time.Stamp
# leafData <- leafData[,-which(colnames(leafData) == "Time.Stamp")]
leafDataWest <- leafData %>%
  select(-starts_with("Area01")) %>%
  select(-starts_with("Area03")) %>%
  select(-starts_with("Area05")) %>%
  select(-starts_with("Area07")) %>%
  select(-starts_with("Area09"))
targetArea <- "Area10_001"
generateModelRegressors <- function(leafDataWest,targetArea) {
  
  # Select only the columns for Area Statuses
  leafDataWestStatuses <- leafDataWest %>%
    select(matches("Area[0-9]+_[0-9]+$"))
  
#   # What if rows lack any "Current" status?
#   rowsWithCurrent <- rowSums(leafDataWestStatuses=="Current")>0
#   leafDataWestStatuses <- leafDataWestStatuses[rowsWithCurrent,]
  
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
  
#   # Mask out data from after last pickup of the year
#   #  (nDaysTilPickup is not a meaningful number here)
#   afterLastPickup <- rcumsum(as.numeric(leafDataWestStatuses[,targetArea]=="Current"))==0
#   nDaysTilPickup <- nDaysTilPickup[!afterLastPickup]
#   nColsFromCurrent <- nColsFromCurrent[!afterLastPickup]
#   timeStamp      <- timeStamp[!afterLastPickup]
  
  # Build a data.frame with regressors
  modelData <- data.frame(nColsFromCurrent)
  
  modelData$status <- factor(leafDataWestStatuses[nrow(leafDataWestStatuses),targetArea],levels=c("Done","Current","Next","Recently Done","Not Done"))
#   modelData$status <- relevel(modelData$status,ref="Done")
  modelData$nCurrent <- rowSums(leafDataWestStatuses[nrow(leafDataWestStatuses),]=="Current")
  modelData$timeStamps <- leafDataWest$Time.Stamp
  modelData$weekOfYear <- format(as.Date(modelData$timeStamps,format="%d-%m-%Y"),"%W")
  modelData$month <- format(as.Date(modelData$timeStamps,format="%d-%m-%Y"),"%m")
  
  modelData
}

thisAreaModel <- cbind(Area=targetArea,generateModelRegressors(leafDataWest,targetArea))
predict(models[[targetArea]],interval="prediction",newdata = thisAreaModel)
