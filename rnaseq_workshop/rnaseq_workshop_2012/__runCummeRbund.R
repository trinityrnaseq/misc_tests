library(cummeRbund);


pdf(file="ladeda.pdf");
plot(1,1);

cuff = readCufflinks('diff_out');

csDensity(genes(cuff));

csScatter(genes(cuff), 'condA', 'condB');

csScatterMatrix(genes(cuff));

csVolcanoMatrix(genes(cuff), 'condA', 'condB');

gene_diff_data = diffData(genes(cuff));
# how many genes?
nrow(gene_diff_data);

sig_gene_data = subset(gene_diff_data,(significant=='yes'));
# how many significant diff expr?
nrow(sig_gene_data);

head(sig_gene_data);

example_diff_gene_id = sig_gene_data$gene_id[1];
example_diff_gene = getGene(cuff, example_diff_gene_id);

expressionBarplot(example_diff_gene, logMode=T, showErrorbars=F);

sig_genes = getGenes(cuff, sig_gene_data$gene_id);
csHeatmap(sig_genes, cluster='both');

plot(5,5);

