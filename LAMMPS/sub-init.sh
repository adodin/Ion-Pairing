#!/bin/bash
#$ -cwd
#$ -pe smp 2-8
#$ -j y
#$ -N IP-min
#$ -V

# REQUIRED ARGS: CATION ANION BC REPLICA_LABEL

# Import sub utility functions
source ./sub-utilities.sh

args_left=$@

# Parse Arguments
parse_global_args $args_left
announce_global_args $args_left
check_cross_node_job

# Make Data Directory      
mkdir -p ${DATADIR}/init/

# Run Job
run_min=True
label=$BC.tip4p.$cation.$anion
while [[ $run_min == True ]]; do
  mpirun -np ${NSLOTS} lmp -in ../LAMMPS/init.lmp -v DATADIR ${DATADIR} -v SEED $SEED \
    -v cation $cation -v anion $anion -v BC ${BC} $@
  if grep -q "WARNING: Only inserted" ${DATADIR}/data.${label}.init; then
    echo "Failed To Place All Ions. Trying Again"
    SEED=$((SEED+1))
  else
    run_min=False
  fi
done

# Move Log File to DATADIR
#clean_up_job
