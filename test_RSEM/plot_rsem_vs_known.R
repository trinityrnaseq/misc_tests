
pdf("known_vs_rsem_plot.pdf")
data = read.table("compare.txt")
R2 = cor(data[,2], data[,3])^2
plot(data[,2], data[,3], main=paste("known vs. rsem, R^2=", R2, sep=''), xlab="known counts", ylab="rsem counts")
dev.off()

