#!/bin/bash
#$ -cwd
#$ -pe smp 2-8
#$ -j y
#$ -V
#$ -N rho_water

# Checks if jobs run across too many jobs
if (( $NHOSTS > 1 )); then
    echo "ERROR: Running on more than one host."
    echo $@ > $JOB_NAME.${JOB_ID}.HOSTERROR
    cat $PE_HOSTFILE >> $JOB_NAME.${JOB_ID}.HOSTERROR
    exit
    
mpirun -np ${NSLOTS} lmp -in rerun-density.lmp -v datafile $1  -v trajfile $2  -v trajEvery 1000 -v outFreq $3 -v last $3 -v DATADIR $4 -v label $5 -v dz 2 -v types ${@:6}
