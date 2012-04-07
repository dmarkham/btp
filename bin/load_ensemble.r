library(randomForest)
library(plyr)
library(gbm)

setwd("~/btp/bin/")


# Append indicators for "NA" and replace NA values with something else
appendNAs <- function(dataset) {
  append_these = data.frame( is.na(dataset[, grep("received_time_diff_last", names(dataset))] ) )
  names(append_these) = paste(names(append_these), "NA", sep = "_")
  dataset = cbind(dataset, append_these)
  dataset[is.na(dataset)] = -1000
  return(dataset)
}



print("Reading the data")
test <-read.csv( "../data/test.csv",  header = TRUE, na.strings = "NA")
test <- appendNAs(test)
print("Done With Data")
ems <- "../models/testrun_ensemble_0.799943.r"

source(ems)


for (i in model_info$uniq_models){     
  load(sprintf("../models/%s",i))
  for (type in c("rf","GBM_model")){

    if(exists(type,inherits=F)){
      if(type == "rf"){
        assign(sprintf("%s",i), rf) 
      } 
      if(type == "GBM_model"){
        assign(sprintf("%s",i), GBM_model) 
      } 
      rm(list=c(type,"score"))
    }
  }
}

print("Making the Default Predictions on the Test Set")

if(is(get(model_info$best)) == "gbm"){
  if(get(model_info$best)$cv.folds > 1){
    best.iter <- gbm.perf(get(model_info$best),method="cv")
  } else
    best.iter <- gbm.perf(get(model_info$best),method="OOB")
  
  predictions = predict(get(model_info$best), test,best.iter)
}

for (i in c(1:model_info$buckets)){
  min <- model_info$span_size * (i-1)
  max <- model_info$span_size * (i)
  
  redorows <- which(predictions >= min & predictions < max )
  if(length(redorows) < 1){
    next
  }
  if(is(get(model_info$models[i])) == "gbm"){
    if(get(model_info$models[i])$cv.folds > 1){
      best.iter <- gbm.perf(get(model_info$models[i]),method="cv")
    } else
      best.iter <- gbm.perf(get(model_info$models[i]),method="OOB")
  
    preds = predict(get(model_info$models[i]), test[redorows,],best.iter)
  }
  else{
    preds = predict(get(model_info$models[i]),test[redorows,])
  }
  
  predictions[redorows] = preds
}



#save(rf , file= sprintf("../models/testrun_%.7f",score ), compress=TRUE, score )


print("Creating the Submission File")
predictions_df  <- data.frame(test$id, predictions)
names(predictions_df)  <- c("id", "trade_price")
write.csv(predictions_df, file = sprintf("../data/testrun_%.7f.csv",model_info$score ), row.names = FALSE)
print("Done")


