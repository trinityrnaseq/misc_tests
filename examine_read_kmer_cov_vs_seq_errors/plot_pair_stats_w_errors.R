library(tidyverse)

df = data.frame(meanval = c(data$left_mean_cov, data$right_mean_cov),
                medianval = c(data$left_median_cov, data$right_median_cov),
                stdev = c(data$left_stdev, data$right_stdev),
                num_errors = c(data$left_errors, data$right_errors))

df$num_errors = as.factor(df$num_errors)

df %>% ggplot(aes(x=meanval, y=stdev, color=num_errors)) + geom_point(alpha=1/2)

df %>% filter(as.numeric(num_errors) < 5) %>% ggplot(aes(x=log(meanval+.1), y=log( (stdev+0.1) / (meanval+.1) ), color=num_errors)) + geom_point(alpha=1/2) + ylim(-4, 2)


df %>% filter(as.numeric(num_errors) < 5) %>% ggplot(aes(log( (stdev) / (meanval) ), color=num_errors)) + geom_density(alpha=0.1) + xlim(-4, 2.5)

df %>% filter(as.numeric(num_errors) < 10) %>% ggplot(aes(( (stdev) / (meanval) ), color=num_errors, fill=num_errors)) + geom_density(alpha=0.1) + xlim(0, 2.5)


