#!/bin/bash
#$ -cwd
#$ -pe mpi 8
#$ -j y
#$ -V
#$ -N rho_water

mpirun -np ${NSLOTS} lmp -in rerun-density.lmp -v datafile ~/DATA/Ion-Pairing/Na.Cl/insulator/replica2/data.insulator.tip4p.Na.Cl.z.a1.0.k.2.5.r.a1.c1.2.5.k.10.0.eq  -v trajfile ~/DATA/Ion-Pairing/Na.Cl/insulator/replica2/prod.insulator.tip4p.Na.Cl.z.a1.0.k.2.5.r.a1.c1.2.5.k.10.0.lammpstrj  -v trajEvery 1000 -v outFreq 1000000 -v last 1000000 -v DATADIR ~/DATA/Ion-Pairing/Na.Cl/insulator/replica2/ -v label water.Drude.insulator.swm4ndp.Na.Cl
