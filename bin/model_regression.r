library(calibrate)

r <- read.csv("../data/results.csv")
#plot(r$Tested,r$Got, xlim= c(.85,.90),ylim=c(.85,.90))


#res=lm(r$Got ~ r$Tested)
res=lm(r$Tested ~ r$Got)


winners <- c( 0.71290,  0.72038,  0.72648,  0.73031,  0.75185,  0.77063,  0.78785,  0.79809,  0.80497 )
for (win in 1:length(winners)) {
  r <- rbind(r,c(winners[win]*res$coefficients[2] + res$coefficients[1],winners[win]))
}



#plot(r$Tested,r$Got,)
plot(r$Got,r$Tested,)
textxy(r$Got,r$Tested,1:nrow(r))


abline(res)

plot_tested <- function(test){
  temp_x <-  (test-res$coefficients[1])/res$coefficients[2]
  points( temp_x, test, col="blue")
  print(temp_x)

}

plot_Got <- function(Got){
  temp_y <-  (Got *res$coefficients[2]) + res$coefficients[1]
  points(  Got,temp_y, col="red")
  print(temp_y)
}



for (win in 1:length(winners)) {
  points( winners[win],winners[win]*res$coefficients[2] + res$coefficients[1], col="red")
}



