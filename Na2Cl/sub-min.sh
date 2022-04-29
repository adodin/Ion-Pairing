#!/bin/bash
#$ -cwd
#$ -pe mpi 8
#$ -j y
#$ -N NaCl-min
#$ -V
#$ -q all.q

let "SEED = ${JOB_ID}"
echo "SEED: $SEED"
DATADIR=~/DATA/Ion-Pairing/NaCl/replica$1/
mkdir $DATADIR

mpirun -np 8 lmp -in min.NaCl.lmp -v DATADIR ${DATADIR} -v SEED $SEED \
  -log ${DATADIR}log.NaCl.min

mv ${JOB_NAME}.o${JOB_ID} ${DATADIR}.