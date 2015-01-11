#!/bin/bash

if [ -e both.fa.gz ] && [ ! -e both.fa ]
then
    gunzip -c both.fa.gz > both.fa
fi

if [ -e iworm.fa.gz ] && [ ! -e iworm.fa ]
then
    gunzip -c iworm.fa.gz > iworm.fa
fi

iworm_file="iworm.fa"
#iworm_file="trouble_iworm.fa"
#iworm_file="iworm_clusters.fa"

if [ ! -e t1.pools ]
then
    echo running t1
    ../../../trunk/Chrysalis/GraphFromFasta -i ${iworm_file} -r both.fa -t 1 -report_welds -max_cluster_size 2000 -debug > t1.out 2>&1
    cat t1.out | grep POOL | cut -f3 - | sort > t1.pools 
    ./count_cluster_size_dist.pl t1.pools > t1.pools.dist
fi

if [ ! -e t5.pools ]
then
    echo running t5
    ../../../trunk/Chrysalis/GraphFromFasta -i ${iworm_file} -r both.fa -t 5 -report_welds -max_cluster_size 2000 -debug > t5.out 2>&1
    cat t5.out | grep POOL | cut -f3 - | sort > t5.pools 
    ./count_cluster_size_dist.pl t5.pools > t5.pools.dist
fi


if [ ! -e t10.pools ] 
then
    echo running t10
    ../../../trunk/Chrysalis/GraphFromFasta -i ${iworm_file} -r both.fa -t 10 -report_welds -max_cluster_size 2000 -debug > t10.out 2>&1
    cat t10.out | grep POOL | cut -f3 - | sort > t10.pools 
    ./count_cluster_size_dist.pl t10.pools > t10.pools.dist
fi

ret=0

t1_diff=`diff -q t1.pools __control_clustering.txt`
if [ "$t1_diff" ]
then
    echo t1: Error
    ret=1
else
    echo t1: OK
fi



t5_diff=`diff -q t5.pools __control_clustering.txt`
if [ "$t5_diff" ]
then
    echo t5: Error
    ret=1
else
    echo t5: OK
fi

t10_diff=`diff -q t10.pools __control_clustering.txt`
if [ "$t10_diff" ]
then
    echo t10: Error
    ret=1
else
    echo t10: OK
fi


exit $ret

