#!/bin/bash
#$ -cwd
#$ -pe mpi 8
#$ -j y
#$ -N Na2Cl-rUS
#$ -t 1-12
#$ -V
#$ -q regular
#$ -hold_jid Na2Cl-min

SGE_TASK_ID=$1
JOB_ID=15325

# Check If Replica Directory Exists
if [ ! -d "/home/adodin/DATA/Ion-Pairing/Na2Cl/replica$1/" ]; then
  echo "ERROR: Base DATA directory does not exist (~/DATA/Ion-Pairing/Na2Cl/replica$1/)"
  exit 11
fi

it_TASK_ID=$(( ${SGE_TASK_ID} - 1 ))
i1=$(( ${it_TASK_ID} % 6 ))
i2=$(( ${it_TASK_ID} / 6 ))

r1=`echo "3.0 + ${i1} * 1.0"|bc`
echo "Bias at r1=$r1 A"
r2=`echo "3.0 + ${i2} * 1.0"|bc`
echo "Bias at r2=$r2 A"
SEED=$(( ${JOB_ID} * ${SGE_TASK_ID} ))
echo "SEED: $SEED"
echo "Bias at r1=$r1 A" >> umbrella.log
echo "Bias at r2=$r2 A" >> umbrella.log
echo "SEED: $SEED" >> umbrella.log
DATADIR=~/DATA/Ion-Pairing/Na2Cl/replica$1/bias_r${r1}_r${r2}/
mkdir $DATADIR
./make-plumed.sh -r $r1 -r 0.5 -r $r2 -r 0.5 ${DATADIR}
mpirun -np 8 lmp -in eq.Na2Cl.lmp -v BIAS 1 -v BIASFILE ${DATADIR}plumed.dat \
  -v SEED $SEED -v DATADIR $DATADIR -log ${DATADIR}log.NaCl.eq -v INPREFIX ../
mpirun -np 8 lmp -in prod.Na2Cl.lmp -v BIAS 1 -v BIASFILE ${DATADIR}plumed.dat \
  -v SEED $SEED -v DATADIR $DATADIR -log ${DATADIR}log.NaCl.prod

mv ${JOB_NAME}.o${JOB_ID}.${SGE_TASK_ID} ${DATADIR}/.
