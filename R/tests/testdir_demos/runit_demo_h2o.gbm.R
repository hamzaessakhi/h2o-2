##
# Test out the h2o.gbm R demo
# It imports a dataset, parses it, and prints a summary
# Then, it runs h2o.gbm on a subset of the dataset
##

setwd(normalizePath(dirname(R.utils::commandArgs(asValues=TRUE)$"f")))
source('../findNSourceUtils.R')

test.h2o.gbm <- function(conn) {
  prosPath = system.file("extdata", "prostate.csv", package="h2o")
  Log.info(paste("Uploading", prosPath))
  prostate.hex = h2o.uploadFile(conn, path = prosPath, key = "prostate.hex")
  
  Log.info("Print out summary of prostate.csv")
  print(summary(prostate.hex))
  
  myX = setdiff(colnames(prostate.hex), "CAPSULE")
  Log.info(paste("Run GBM with y = CAPSULE, x =", paste(myX, collapse=",")))
  prostate.gbm = h2o.gbm(x = setdiff(colnames(prostate.hex), "CAPSULE"), y = "CAPSULE", data = prostate.hex, n.trees = 10, interaction.depth = 5, shrinkage = 0.1)
  print(prostate.gbm)
  
  Log.info("Run GBM with y = CAPSULE, x = AGE, RACE, PSA, VOL, GLEASON")
  prostate.gbm2 = h2o.gbm(x = c("AGE", "RACE", "PSA", "VOL", "GLEASON"), y = "CAPSULE", data = prostate.hex, n.trees = 10, interaction.depth = 8, n.minobsinnode = 10, shrinkage = 0.2)
  print(prostate.gbm2)
  
  irisPath = system.file("extdata", "iris.csv", package="h2o")
  Log.info(paste("Uploading", irisPath))
  iris.hex = h2o.uploadFile(conn, path = irisPath, key = "iris.hex")
  
  Log.info("Print out summary of iris.csv")
  summary(iris.hex)
  
  Log.info("Run GBM with y = column 5, x = columns 1:4")
  iris.gbm = h2o.gbm(x = 1:4, y = 5, data = iris.hex)
  print(iris.gbm)
  
  testEnd()
}

doTest("Test out the h2o.gbm R demo", test.h2o.gbm)
