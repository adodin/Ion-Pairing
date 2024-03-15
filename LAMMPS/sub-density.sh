#!/bin/bash
#$ -cwd
#$ -pe mpi 8
#$ -j y
#$ -V
#$ -N rho_water
#$ -q regular

mpirun -np 8 lmp -in rerun-density.lmp -v datafile ~/DATA/Ion-Pairing/Gdm.Cl/slab/replica2/data.Drude.slab.swm4ndp.Gdm.Cl.eq -v trajfile ~/DATA/Ion-Pairing/Gdm.Cl/slab/replica2/prod.Drude.slab.swm4ndp.Gdm.Cl.lammpstrj -v trajEvery 1000 -v outFreq 15000000 -v last 15000000 -v DATADIR ~/DATA/Ion-Pairing/Gdm.Cl/slab/replica2/ -v label water.Drude.slab.swm4ndp.Gdm.Cl
