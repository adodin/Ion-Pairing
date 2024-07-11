#!/bin/bash
#$ -cwd
#$ -pe smp 8
#$ -j y
#$ -V
#$ -N rho_water

mpirun -np ${NSLOTS} lmp -in rerun-density.lmp -v datafile $1  -v trajfile $2  -v trajEvery 1000 -v outFreq $3 -v last $3 -v DATADIR $4 -v label $5 -v types 5 7 -v type_labels C Cl -v dz 2
