#!/bin/bash
#$ -cwd
#$ -pe mpi 8
#$ -j y
#$ -N IPU-prod
#$ -V
#$ -q regular
#$ -hold_jid_ad IPU-eq

# REQUIRED ARGS: CATION ANION BC REPLICA_LABEL [BIAS STRINGS]
# Bias String options (Each Add a Loop Layer):
# -z c|a|id N k z0_min dz num_z
# -r c|a|id N c|a|id M k r0_min dr num_r

# Get Current Working Directory
WORKINGDIR=$( pwd )/

# Parse Required Args
cation=$1
shift
anion=$1
shift
BC=${BC}
shift
replica=$1
shift

# Construct Data Directory Label
DATADIR=~/DATA/Ion-Pairing/${cation}.${anion}/${BC}/replica${replica}/

# Function for Array Product
prod() {      
  local mul=1 
  for i
  do 
    ((mul *= i))
  done
  echo $mul
}


# Parse Bias Specifications
biasTypes=()
biasIDs=()
biasKs=()
biasMins=()
biasDs=()
biasNs=()
while :; do
  case $1 in
    -z)
      biasTypes+=("z")
      shift
      biasIDs+=("$1 $2")
      shift 2
      biasKs+=($1)
      shift
      biasMins+=($1)
      shift
      biasDs+=($1)
      shift
      biasNs+=($1)
      shift
    ;;
    -r)
      biasTypes+=("r")
      shift
      biasIDs+=("$1 $2 $3 $4")
      shift 4
      biasKs+=($1)
      shift
      biasMins+=($1)
      shift
      biasDs+=($1)
      shift
      biasNs+=($1)
      shift
    ;;
    *)
      break
  esac
done

echo "==================================================="
biasString=""
echo "TASK: $SGE_TASK_ID"
for (( i=0; i<=${#biasTypes[@]}-1; i++ )); do
  fDiv=$(prod ${biasNs[@]:$((i+1))})
  ind=$(((($SGE_TASK_ID-1)/$fDiv)%${biasNs[i]}))
  b0=$(bc <<< "${biasMins[i]}+${biasDs[i]}*$ind")
  biasString+=" -v ${biasTypes[i]}Bias ${biasIDs[i]} $b0 ${biasKs[i]}"
  echo "---------------------------------------------------"
  echo "${biasTypes[i]} Bias:"
  echo "  Biasing: ${biasIDs[i]}"
  echo "  At: $b0"
  echo "  K: ${biasKs[i]}"
done
echo "Bias String: ${biasString}"
echo "==================================================="

# Announce Settings
echo "Script Directory: $WORKINGDIR"
echo "Data Directory: $DATADIR"
echo "Cation: $cation"
echo "Anion: $anion"
echo "Boundary Condition: $BC"
echo "Replica: $replica"
let "SEED = ${JOB_ID}"
echo "SEED: $SEED"
echo "Optional Arguments: $@"

# Create DATADIR
mkdir $DATADIR

# Run Job
mpirun -np 8 lmp -in run.lmp -v skipEquil True -v DATADIR ${DATADIR} -v SEED $SEED \
  -v cation $cation -v anion $anion -v BC $BC ${biasString} $@

# Move Log File to DATADIR
mv ${WORKINGDIR}/${JOB_NAME}.o${JOB_ID} ${DATADIR}.
