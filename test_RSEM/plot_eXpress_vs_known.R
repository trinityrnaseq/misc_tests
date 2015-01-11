
pdf("known_vs_eXpress_plot.pdf")
data = read.table("results.xprs.wKnown")
R2 = cor(data[,2], data[,3])^2
plot(data[,2], data[,3], main=paste("known vs. eXpress, R^2=", R2, sep=''), xlab="known counts", ylab="eXpress est counts")
dev.off()

