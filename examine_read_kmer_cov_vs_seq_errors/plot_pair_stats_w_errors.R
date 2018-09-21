library(tidyverse)

df = data.frame(meanval = c(data$left_mean_cov, data$right_mean_cov),
                medianval = c(data$left_median_cov, data$right_median_cov),
                stdev = c(data$left_stdev, data$right_stdev),
                num_errors = c(data$left_errors, data$right_errors))

df$num_errors = as.factor(df$num_errors)

df %>% ggplot(aes(x=meanval, y=stdev, color=num_errors)) + geom_point(alpha=1/2)

