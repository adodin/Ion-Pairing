#!/bin/bash
#$ -cwd
#$ -pe mpi 8
#$ -j y
#$ -N IP-eq
#$ -V
#$ -q regular
#$ -hold_jid IP-min

# REQUIRED ARGS: CATION ANION REPLICA_LABEL

# Get Current Working Directory
WORKINGDIR=$( pwd )/

# Parse Required Args
cation=$1
shift
anion=$1
shift
replica=$1
shift

# Construct Data Directory Label
DATADIR=~/DATA/Ion-Pairing/${cation}.${anion}/replica${replica}/

# Announce Settings
echo "Script Directory: $SCRIPTDIR"
echo "Data Directory: $DATADIR"
echo "Cation: $cation"
echo "Anion: $anion"
echo "Replica: $replica"
let "SEED = ${JOB_ID}"
echo "SEED: $SEED"
echo "Optional Arguments: $@"

# Create DATADIR
mkdir $DATADIR

# Run Job
mpirun -np 8 lmp -in run.lmp -v skipProd True -v DATADIR ${DATADIR} -v SEED $SEED \
  -v cation $cation -v anion $anion $@

# Move Log File to DATADIR
mv ${WORKINGDIR}/${JOB_NAME}.o${JOB_ID} ${DATADIR}.
