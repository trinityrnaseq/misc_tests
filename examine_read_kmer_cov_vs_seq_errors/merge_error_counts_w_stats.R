data = read.table("pairs.K25.stats", header=T, row.names=1)
error_stats = read.table("errors_per_read.txt", row.names=1, header=F)


data = cbind(data, left_errors=NA, right_errors=NA)
left_error_stats =  error_stats[rownames(error_stats) %in% data$left_acc,,drop=F]
right_error_stats =  error_stats[rownames(error_stats) %in% data$right_acc,,drop=F]

data$left_errors[match(rownames(left_error_stats), data$left_acc)] = left_error_stats[,1]
data$right_errors[match(rownames(right_error_stats), data$right_acc)] = right_error_stats[,1]

write.table(data, file="pair_stats_w_seq_error_counts.txt", quote=F, sep="\t")


           
