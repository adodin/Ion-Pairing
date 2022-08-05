#!/bin/bash
#$ -cwd
#$ -pe mpi 4
#$ -j y
#$ -N Na2Cl-z
#$ -t 1-41
#$ -V
#$ -q ibnet
#$ -hold_jid Na2Cl-min


# Check If Replica Directory Exists
if [ ! -d "/home/adodin/DATA/Ion-Pairing/Na2Cl/replica$1/" ]; then
  echo "ERROR: Base DATA directory does not exist (~/DATA/Ion-Pairing/Na2Cl/replica$1/)"
  exit 11
fi

r=`echo "${SGE_TASK_ID} * 0.5 - 0.5"|bc`
echo "Bias at z=$r A"
let "SEED = ${JOB_ID}*${SGE_TASK_ID}"
echo "SEED: $SEED"
echo "Bias at z=$r A" >> umbrella.log
echo "SEED: $SEED" >> umbrella.log
DATADIR=~/DATA/Ion-Pairing/Na2Cl-slab/replica$1/bias_z$r/
mkdir $DATADIR
./make-plumed.sh -z $r -z 20 -c 200 ${DATADIR}
mpirun -np 4 lmp -in eq.Na2Cl.lmp -v BIAS 1 -v BIASFILE ${DATADIR}plumed.dat \
  -v SEED $SEED -v DATADIR $DATADIR -log ${DATADIR}log.NaCl.eq -v INPREFIX ../
mpirun -np 4 lmp -in prod.Na2Cl.lmp -v BIAS 1 -v BIASFILE ${DATADIR}plumed.dat \
  -v SEED $SEED -v DATADIR $DATADIR -log ${DATADIR}log.NaCl.prod

mv ${JOB_NAME}.o${JOB_ID}.${SGE_TASK_ID} ${DATADIR}/.
