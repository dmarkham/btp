library(randomForest)
library(plyr)

setwd("~/btp/bin/")

# Seed the random number generator for reproducibility
set.seed(44)

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
#train = train[1:20000,]


print("Training the Random Forest")
rf <- randomForest(train[,-c(1,2,3)],train$trade_price, do.trace=TRUE,importance=TRUE, sampsize=10000, ntree = 50)

print("Making Predictions on the Test Set")
predictions = predict(rf, test)

score <- evaluation(predictions,test$trade_price,test$weight)


save(rf , file= sprintf("../models/testrun_%.7f",score ), compress=TRUE,score )


print("Creating the Submission File")
predictions_df  <- data.frame(test$id, predictions)
names(predictions_df)  <- c("id", "trade_price")
write.csv(predictions_df, file = sprintf("../data/testrun_%.7f.csv",score ), row.names = FALSE)



