#!/bin/bash
#$ -cwd
#$ -pe mpi 8
#$ -j y
#$ -N Na2Cl-rUS
#$ -t 1-12
#$ -V
#$ -q regular
#$ -hold_jid Na2Cl-min


# Check If Replica Directory Exists
if [ ! -d "/home/adodin/DATA/Ion-Pairing/Na2Cl/replica$1/" ]; then
  echo "ERROR: Base DATA directory does not exist (~/DATA/Ion-Pairing/Na2Cl/replica$1/)"
  exit 11
fi

r=`echo "3.0 + ${SGE_TASK_ID} * 0.5"|bc`
echo "Bias at r=$r A"
let "SEED = ${JOB_ID}*${SGE_TASK_ID}"
echo "SEED: $SEED"
echo "Bias at r=$r A" >> umbrella.log
echo "SEED: $SEED" >> umbrella.log
DATADIR=~/DATA/Ion-Pairing/Na2Cl/replica$1/bias_r$r/
mkdir $DATADIR
./make-plumed.sh -r $r -r 1.0 ${DATADIR}
mpirun -np 8 lmp -in eq.Na2Cl.lmp -v BIAS 1 -v BIASFILE ${DATADIR}plumed.dat \
  -v SEED $SEED -v DATADIR $DATADIR -log ${DATADIR}log.NaCl.eq -v INPREFIX ../
mpirun -np 8 lmp -in prod.Na2Cl.lmp -v BIAS 1 -v BIASFILE ${DATADIR}plumed.dat \
  -v SEED $SEED -v DATADIR $DATADIR -log ${DATADIR}log.NaCl.prod

mv ${JOB_NAME}.o${JOB_ID}.${SGE_TASK_ID} ${DATADIR}/.
