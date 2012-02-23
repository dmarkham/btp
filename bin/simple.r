library(randomForest)
library(plyr)

# Seed the random number generator for reproducibility
set.seed(68768768)

print("Reading the data")
train <-read.csv( "../data/train.csv",  header = TRUE, na.strings = "NA")
test <-read.csv( "../data/test.csv",  header = TRUE, na.strings = "NA")

# Uncomment the line below to use only a small portion of the training data
# train = train[1:20000,]

# Append indicators for "NA" and replace NA values with something else
appendNAs <- function(dataset) {
  append_these = data.frame( is.na(dataset[, grep("received_time_diff_last", names(dataset))] ) )
  names(append_these) = paste(names(append_these), "NA", sep = "_")
  dataset = cbind(dataset, append_these)
  dataset[is.na(dataset)] = -1000
  return(dataset)
}

print("Resolving NAs")
train <- appendNAs(train)
test <- appendNAs(test)

print("Training the Random Forest")
rf <- randomForest(train[,-c(1,2,3)],train$trade_price, do.trace=TRUE,importance=TRUE, sampsize = 10000, ntree = 200)

print("Making Predictions on the Test Set")
predictions = predict(rf, test)

print("Creating the Submission File")
predictions_df  <- data.frame(test$id, predictions)
names(predictions_df)  <- c("id", "trade_price")
write.csv(predictions_df, file = "random_forest_sample_submission.csv", row.names = FALSE)

