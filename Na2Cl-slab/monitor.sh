#!/bin/bash

file=`ls Na2Cl-rUS.o150*|sort -R|tail -1`
rep=`sed -En 's/.*replica([0-9]).*/\1/p' $file`

echo "Replica: $rep"
head -2 $file
tail $file
