## so we get the same awsner every time when splitting the file
set.seed(42)

setwd("~/btp/bin/")


train <-read.csv( "../data/train.csv",  header = TRUE, na.strings = "NA")
test <-read.csv( "../data/test.csv",  header = TRUE, na.strings = "NA")

model_test <- nrow(test)/ nrow(train) *nrow(train)
model_train <- nrow(train) - model_train

test_rows <- train[sample(nrow(train),model_test),]
train_rows <- train[-test_rows[,1],]

write.table(test_rows, file="../data/train_part_test.csv", row.names=FALSE, sep=",")
write.table(train_rows, file="../data/train_part_train.csv", row.names=FALSE, sep=",")




