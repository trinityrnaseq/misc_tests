#!/bin/bash -ve


if [ -s example_Casava.fq.gz ] && [ ! -s example_Casava.fq ]; then
    gunzip -c example_Casava.fq.gz > example_Casava.fq
fi


../../../trunk/util/fastQ_to_fastA.pl -I example_Casava.fq
