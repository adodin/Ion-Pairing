#!/bin/bash
#$ -cwd
#$ -pe smp 8
#$ -j y
#$ -N IP-min
#$ -V

# REQUIRED ARGS: CATION ANION BC REPLICA_LABEL

# Get Current Working Directory
WORKINGDIR=$( pwd )/

# Parse Required Args
cation=$1
shift
anion=$1
shift
BC=$1
shift
replica=$1
shift

# Construct Data Directory Label
DATADIR=~/DATA/Ion-Pairing/${cation}.${anion}/
mkdir ${DATADIR}
DATADIR=${DATADIR}${BC}/
mkdir ${DATADIR}
DATADIR=${DATADIR}replica${replica}/

# Announce Settings
echo "Script Directory: $WORKINGDIR"
echo "Data Directory: $DATADIR"
echo "Cation: $cation"
echo "Anion: $anion"
echo "Boundary Condition: $BC"
echo "Replica: $replica"
let "SEED = ${JOB_ID}"
echo "SEED: $SEED"
echo "Optional Arguments: $@"

# Create DATADIR
mkdir $DATADIR

# Run Job
run_min=True
label=$BC.tip4p.$cation.$anion
while [[ $run_min == True ]]; do
  mpirun -np ${NSLOTS} lmp -in init.lmp -v DATADIR ${DATADIR} -v SEED $SEED \
    -v cation $cation -v anion $anion -v BC ${BC} $@
  if grep -q "WARNING: Only inserted" ${DATADIR}/data.${label}.init; then
    echo "Failed To Place All Ions. Trying Again"
    SEED=$((SEED+1))
  else
    run_min=False
  fi
done


# Move Log File to DATADIR
mv ${WORKINGDIR}/${JOB_NAME}.o${JOB_ID} ${DATADIR}.
