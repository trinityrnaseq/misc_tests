#!/bin/bash 



if [ ! -e t1.pools ]
then
    echo running t1
../../../Chrysalis/GraphFromFasta -i inchworm.K25.L25.fa -r reads.fa -t 1 -max_cluster_size 10000 -scaffolding iworm_scaffolds.txt -no_welds > t1.out
    cat t1.out | grep POOL | cut -f3 - | sort > t1.pools 
    ./count_cluster_size_dist.pl t1.pools > t1.pools.dist
fi


if [ ! -e t5.pools ]
then
    echo running t5
../../../Chrysalis/GraphFromFasta -i inchworm.K25.L25.fa -r reads.fa -t 5 -max_cluster_size 10000 -scaffolding iworm_scaffolds.txt -no_welds > t5.out
    cat t5.out | grep POOL | cut -f3 - | sort > t5.pools 
    ./count_cluster_size_dist.pl t5.pools > t5.pools.dist
fi


if [ ! -e t10.pools ]
then
    echo running t10
../../../Chrysalis/GraphFromFasta -i inchworm.K25.L25.fa -r reads.fa -t 10 -max_cluster_size 10000 -scaffolding iworm_scaffolds.txt -no_welds > t10.out
    cat t10.out | grep POOL | cut -f3 - | sort > t10.pools 
    ./count_cluster_size_dist.pl t10.pools > t10.pools.dist
fi


ret=0

t1_diff=`diff -q t1.pools __true_SL_clustering_results.txt`
if [ -s "t1.pools" ] && [ "$t1_diff" ]
then
    echo t1: Error
    ret=1
else
    echo t1: OK
fi



t5_diff=`diff -q t5.pools __true_SL_clustering_results.txt`
if [ -s "t5.pools" ] && [ "$t5_diff" ]
then
    echo t5: Error
    ret=1
else
    echo t5: OK
fi

t10_diff=`diff -q t10.pools __true_SL_clustering_results.txt`
if [ -s "t10.pools" ] && [ "$t10_diff" ]
then
    echo t10: Error
    ret=1
else
    echo t10: OK
fi


exit $ret

