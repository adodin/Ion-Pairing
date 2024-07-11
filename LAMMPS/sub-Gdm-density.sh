#!/bin/bash
#$ -cwd
#$ -pe smp 8
#$ -l slots=2
#$ -j y
#$ -V
#$ -N rho_water

mpirun -np ${NSLOTS} lmp -in rerun-density.lmp -v datafile ~/DATA/Ion-Pairing/Gdm.Cl/slab/replica2/data.Drude.slab.swm4ndp.Gdm.Cl.eq -v trajfile ~/DATA/Ion-Pairing/Gdm.Cl/slab/replica2/prod.Drude.slab.swm4ndp.Gdm.Cl.lammpstrj -v trajEvery 1000 -v outFreq 15000000 -v last 15000000 -v DATADIR ~/DATA/Ion-Pairing/Gdm.Cl/slab/replica2/ -v label water.Drude.slab.swm4ndp.Gdm.Cl
