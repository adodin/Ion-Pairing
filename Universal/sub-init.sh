#!/bin/bash
#$ -cwd
#$ -pe mpi 8
#$ -j y
#$ -N IP-min
#$ -V
#$ -q regular

# REQUIRED ARGS: CATION ANION REPLICA_LABEL

# Get Script Directory to make sure we find LAMMPS input Files
SCRIPTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Get Current Working Directory to find Log Files
WORKINGDIR=$( pwd )

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

# Create and Move to DATADIR
mkdir $DATADIR
cd $DATADIR

# Run Job
mpirun -np 8 lmp -in ${SCRIPTDIR}min.NaCl.lmp -v DATADIR ${DATADIR} -v SEED $SEED \
  -v cation $cation -v anion $anion $@

# Move Log File to DATADIR
mv ${WORKINGDIR}/${JOB_NAME}.o${JOB_ID} ${DATADIR}.
