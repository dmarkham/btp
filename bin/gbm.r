library(plyr)
library(gbm)

setwd("~/btp/bin/")


evaluation <- function(prediction,actual,weight ){ return(sum(abs(prediction - actual) * weight) / sum(weight))   }
# Append indicators for "NA" and replace NA values with something else
appendNAs <- function(dataset) {
  append_these = data.frame( is.na(dataset[, grep("received_time_diff_last", names(dataset))] ) )
  names(append_these) = paste(names(append_these), "NA", sep = "_")
  dataset = cbind(dataset, append_these)
  dataset[is.na(dataset)] = -1000
  return(dataset)
}



print("Reading the data")
#train <-read.csv( "../data/train_part_train.csv",  header = TRUE, na.strings = "NA")
#test <-read.csv( "../data/train_part_test.csv",  header = TRUE, na.strings = "NA")
print("Resolving NAs")
#train <- appendNAs(train)
#test <- appendNAs(test)


# Uncomment the line below to use only a small portion of the training data
#train = train[1:10000,]


folds <- sample(1:3,1)
GBM_NTREES <- sample(500:1000,1)
GBM_SHRINKAGE <- sample(1:50,1)/1000 
GBM_DEPTH <-  sample(4:10,1)
GBM_MINOBS <- sample(20:150,1)
#if(length(trainrows) < GBM_MINOBS){
#  GBM_MINOBS <- round(length(trainrows) * .3);
#}
 
GBM_model <- gbm(
                     trade_price ~ .,
                     data = train[,-c(1,2,61:71)],
                     distribution = "gaussian" ,
                     n.trees = GBM_NTREES ,
                     shrinkage = GBM_SHRINKAGE ,
                     interaction.depth = GBM_DEPTH,
                     n.minobsinnode = GBM_MINOBS ,
                     bag.fraction = 0.5,
                     verbose = TRUE,
                     cv.folds = folds,
                     keep.data = FALSE,
                     )   

if(folds > 1){
  best.iter <- gbm.perf(GBM_model,method="cv")
} else
  best.iter <- gbm.perf(GBM_model,method="OOB") 
 
print("Making Predictions on the Test Set")
predictions <- predict.gbm( object = GBM_model , newdata =  test[, -c(1,2,3)] , best.iter )

score <- evaluation(predictions,test$trade_price,test$weight)


save(GBM_model , file= sprintf("../models/testrun_%.7f",score ), compress=TRUE,score )


print("Creating the Submission File")
predictions_df  <- data.frame(test$id, predictions)
names(predictions_df)  <- c("id", "trade_price")
write.csv(predictions_df, file = sprintf("../data/testrun_%.7f.csv",score ), row.names = FALSE)

