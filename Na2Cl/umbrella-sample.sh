for i in {0..11}; do
  r=`echo "3.5 + $i * 0.5"|bc`
  echo "Bias at r=$r A"
  SEED=$RANDOM
  echo "SEED: $RANDOM"
  echo "Bias at r=$r A" >> umbrella.log
  echo "SEED: $RANDOM" >> umbrella.log
  DATADIR=~/Documents/DATA/Ion-Pairing/NaCl/bias_r$r/
  mkdir $DATADIR
  ./make-plumed.sh -r $r -r 1.0 ${DATADIR}
  mpirun -np 6 lmp -in eq.NaCl.lmp -v BIAS 1 -v BIASFILE ${DATADIR}plumed.dat \
    -v SEED $SEED -v DATADIR $DATADIR -log ${DATADIR}log.NaCl.eq -v INPREFIX ../
  mpirun -np 6 lmp -in prod.NaCl.lmp -v BIAS 1 -v BIASFILE ${DATADIR}plumed.dat \
    -v SEED $SEED -v DATADIR $DATADIR -log ${DATADIR}log.NaCl.prod
done
