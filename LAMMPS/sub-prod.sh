#!/bin/bash
#$ -cwd
#$ -pe mpi 8
#$ -j y
#$ -N IP-prod
#$ -V
#$ -q regular
#$ -hold_jid IP-eq

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
DATADIR=~/DATA/Ion-Pairing/${cation}.${anion}/${BC}/replica${replica}/

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
mpirun -np 8 lmp -in run.lmp -v skipEquil True -v DATADIR ${DATADIR} -v SEED $SEED \
  -v cation $cation -v anion $anion -v BC $BC $@

# Move Log File to DATADIR
mv ${WORKINGDIR}/${JOB_NAME}.o${JOB_ID} ${DATADIR}.
