#!/bin/bash
#$ -cwd
#$ -pe mpi 8
#$ -j y
#$ -N Na2Cl-min
#$ -V
#$ -q regular

let "SEED = ${JOB_ID}"
echo "SEED: $SEED"
DATADIR=~/DATA/Ion-Pairing/Na2Cl/replica$1/
mkdir $DATADIR

mpirun -np 8 lmp -in min.Na2Cl.lmp -v DATADIR ${DATADIR} -v SEED $SEED \
  -log ${DATADIR}log.NaCl.min

mv ${JOB_NAME}.o${JOB_ID} ${DATADIR}.
