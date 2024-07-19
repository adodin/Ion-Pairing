#!/bin/bash
#$ -cwd
#$ -pe smp 2-24
#$ -j y
#$ -N IP-run
#$ -V
#$ -hold_jid IP-min

# REQUIRED ARGS: CATION ANION BC REPLICA_LABEL

# Import sub utility functions
source sub-utilities.sh

# Parse Arguments
parse_global_args
announce_global_args
check_cross_node_job

# Create DATADIR
mkdir -p $DATADIR/equil/
mkdir -p ${DATADIR}/prod/

# Run Job
mpirun -np ${NSLOTS} lmp -in ../LAMMPS/run.lmp -v DATADIR ${DATADIR} -v SEED $SEED \
  -v cation $cation -v anion $anion -v BC $BC $@

# Move Log File to DATADIR
clean_up_job
