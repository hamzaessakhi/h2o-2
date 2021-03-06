#----------------------------------------------------------------------
# Purpose:  This test exercises HDFS operations from R.
#----------------------------------------------------------------------

setwd(normalizePath(dirname(R.utils::commandArgs(asValues=TRUE)$"f")))
source('../findNSourceUtils.R')

ipPort <- get_args(commandArgs(trailingOnly = TRUE))
myIP   <- ipPort[[1]]
myPort <- ipPort[[2]]
hdfs_name_node <- Sys.getenv(c("NAME_NODE"))
print(hdfs_name_node)

library(RCurl)
library(testthat)
library(h2o)

heading("BEGIN TEST")
conn <- h2o.init(ip=myIP, port=myPort, startH2O = FALSE)

hdfs_airlines_file = "/datasets/airlines_all.csv"

#----------------------------------------------------------------------
# Single file cases.
#----------------------------------------------------------------------

heading("Testing single file importHDFS")
url <- sprintf("hdfs://%s%s", hdfs_name_node, hdfs_airlines_file)
data.hex <- h2o.importFile(conn, url)

n <- nrow(data.hex)
print(n)
if (n != 116695259) {
    stop("nrows is wrong")
}

if (class(data.hex) != "H2OFrame") {
    stop("data.hex is the wrong type")
}
print ("Import worked")

## First choose columns to ignore
IgnoreCols <- c('DepTime','ArrTime','FlightNum','TailNum','ActualElapsedTime','AirTime','ArrDelay','DepDelay','TaxiIn','TaxiOut','Cancelled','CancellationCode','CarrierDelay','WeatherDelay','NASDelay','SecurityDelay','LateAircraftDelay','Diverted')

## Then remove those cols from validX list
myX <- which(!(names(data.hex) %in% IgnoreCols))

## Chose which col as response
DepY <- "IsDepDelayed"

# Chose functions glm, gbm, deeplearning
# obj name | function call | x = predictors | y = response | training_frame = airlines
#

## Build GLM Model and compare AUC with h2o1
air.glm <- h2o.glm(x = myX, y = DepY, data = data.hex, family = "binomial")
pred_glm = h2o.predict(air.glm, data.hex)
auc_glm <- h2o.performance(pred_glm[,3], data.hex[ ,DepY], measure = "auc")
print(auc_glm)
expect_true(abs(auc_glm - 0.79) < 0.01)

IgnoreCols_1 <- c('Year','Month','DayofMonth','DepTime','DayOfWeek','ArrTime','TailNum','ActualElapsedTime','AirTime','ArrDelay','DepDelay','TaxiIn','TaxiOut','Cancelled','CancellationCode','Diverted','CarrierDelay','WeatherDelay','NASDelay','SecurityDelay','LateAircraftDelay')

## Then remove those cols from validX list
myX1 <- which(!(names(data.hex) %in% IgnoreCols_1))

air.gbm <- h2o.gbm(x = myX1, y = DepY, data = data.hex, distribution = "bernoulli", ntrees=50)
pred_gbm = h2o.predict(air.gbm, data.hex)
auc_gbm <- h2o.performance(pred_gbm[,3], data.hex[ ,DepY], measure = "auc")
print(auc_gbm)
expect_true(abs(auc_gbm - 0.80) < 0.01)

air.dl  <- h2o.deeplearning(x = myX1, y = DepY, data = data.hex, epochs=1, hidden=c(50,50), loss = "CrossEntropy")
pred_dl = h2o.predict(air.dl, data.hex)
auc_dl <- h2o.performance(pred_dl[,3], data.hex[ ,DepY], measure = "auc")
print(auc_dl)
expect_true(abs(auc_dl - 0.80) <= 0.02)

PASS_BANNER()
