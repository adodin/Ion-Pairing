#!/bin/bash
#$ -cwd
#$ -pe mpi 4
#$ -j y
#$ -N Na2Cl-rUS
#$ -t 1-36
#$ -V
#$ -q ibnet
#$ -hold_jid Na2Cl-min

# Check If Replica Directory Exists
if [ ! -d "/home/adodin/DATA/Ion-Pairing/Na2Cl-slab/replica$1/" ]; then
  echo "ERROR: Base DATA directory does not exist (~/DATA/Ion-Pairing/Na2Cl-slab/replica$1/)"
  exit 11
fi

it_TASK_ID=$(( ${SGE_TASK_ID} - 1 ))
i1=$(( ${it_TASK_ID} % 3 ))
i2=$(( ${it_TASK_ID} / 3 ))

if [ $i1 == 0 ]; then
    z=8.0
elif [ $i1 == 1 ]; then
    z=10.0
elif  [ $i1 == 2 ]; then
    z=14.0
fi

echo "Bias at z=$z A"
r=`echo "3.5 + ${i2} * 0.5"|bc`
echo "Bias at r=$r A"
SEED=$(( ${JOB_ID} * ${SGE_TASK_ID} ))
echo "SEED: $SEED"
echo "Bias at z=$z A" >> umbrella.log
echo "Bias at r=$r A" >> umbrella.log
echo "SEED: $SEED" >> umbrella.log
DATADIR=~/DATA/Ion-Pairing/Na2Cl-slab/replica$1/bias_z${z}_r${r}/
mkdir $DATADIR
./make-plumed.sh -z $z -z 20 -r $r -r 10 -c 200 ${DATADIR}
mpirun -np 4 lmp -in eq.Na2Cl.lmp -v BIAS 1 -v BIASFILE ${DATADIR}eq.plumed.dat \
  -v SEED $SEED -v DATADIR $DATADIR -log ${DATADIR}log.NaCl.eq -v INPREFIX ../
mpirun -np 4 lmp -in prod.Na2Cl.lmp -v BIAS 1 -v BIASFILE ${DATADIR}plumed.dat \
  -v SEED $SEED -v DATADIR $DATADIR -log ${DATADIR}log.NaCl.prod

mv ${JOB_NAME}.o${JOB_ID}.${SGE_TASK_ID} ${DATADIR}/.