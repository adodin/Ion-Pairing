#!/bin/bash
#$ -cwd
#$ -pe smp 2-8
#$ -j y
#$ -N IP-run
#$ -V
#$ -hold_jid IP-min

# REQUIRED ARGS: CATION ANION BC REPLICA_LABEL [BIAS STRINGS]
# Bias String options (Each Add a Loop Layer):
# -z c|a|id N k z0_min dz num_z
# -r c|a|id N c|a|id M k r0_min dr num_r

# Import sub utility functions
source ./sub-utilities.sh

args_left=$@

# Parse Arguments
parse_global_args $args_left
if [ ${SGE_TASK_ID} != "undefined" ]; then
  parse_umbrella_bias_spec $args_left
  construct_bias_string 
fi
announce_global_args $args_left
check_cross_node_job

# Create DATADIR
mkdir -p $DATADIR/equil/
mkdir -p ${DATADIR}/prod/

# Run Job
mpirun -np ${NSLOTS} lmp -in run.lmp -v DATADIR ${DATADIR} -v SEED $SEED \
  -v cation $cation -v anion $anion -v BC $BC ${biasString} $args_left

# Move Log File to DATADIR
DATADIR=${DATADIR}/prod/
clean_up_job
