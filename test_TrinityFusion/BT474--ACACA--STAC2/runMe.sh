if [ ! -e BT474--ACACA--STAC2.left.fq ]; then
    gunzip -c BT474--ACACA--STAC2.left.fq.gz > BT474--ACACA--STAC2.left.fq
fi

if [ ! -e BT474--ACACA--STAC2.right.fq ]; then
    gunzip -c BT474--ACACA--STAC2.right.fq.gz > BT474--ACACA--STAC2.right.fq
fi


../../../trunk/Trinity --seqType fq --left BT474--ACACA--STAC2.left.fq --right BT474--ACACA--STAC2.right.fq --JM 10G --CPU 1 --min_iso_expr 0

~/SVN/KCO/SOFTWARE/RNASEQ_FusionFinders/run_Trinity_Fusion_Pipeline.pl  -T trinity_out_dir/Trinity.fasta --left BT474--ACACA--STAC2.left.fq  --right BT474--ACACA--STAC2.right.fq -o trinFuse --ref_GTF /seq/regev_genome_portal/RESOURCES/human/Hg19/gencode.v19/gencode.v19.rna_seq_pipeline.gtf
