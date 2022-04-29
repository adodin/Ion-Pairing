#!/bin/bash

# Set Flags for each cosntraint
rflag=0
krspec=0
zflag=0
kzspec=0
cflag=0

while getopts r:z:c: flag
do
    case "${flag}" in
	r) if [ $rflag = 0 ]; then
    rflag=1
    r=${OPTARG}
  else
    krspec=1
    kr=${OPTARG}
  fi;;
	z) if [ $zflag = 0 ]; then
    zflag=1
    z=${OPTARG}
  else
    kzspec=1
    kz=${OPTARG}
  fi;;
	c) cflag=1
  kc=${OPTARG};;
	esac
done

dirname=${@:$OPTIND:1}
fname=${dirname}plumed.dat

if [ ${rflag} = 1 ] && [ ${krspec} = 0 ]; then
  echo "ERROR: Must specify kr spring constant"
  exit 1
fi

if [ ${zflag} = 1 ] && [ ${kzspec} = 0 ]; then
  echo "ERROR: Must specify kz spring constant"
  exit 2
fi

echo "Saving PLUMED bias to: ${fname}"

cat >${fname} << EOF
UNITS LENGTH=A ENERGY=kcal/mol
r: DISTANCE ATOMS=2045,2046
p: POSITION ATOM=2045
cAt: COM ATOMS=1-2046
c: POSITION ATOM=cAt
EOF

if [ ${rflag} = 1 ]; then
    echo "Using r constraint: (r=$r; kr=$kr)"
    echo "rRestraint: RESTRAINT ARG=r AT=${r} KAPPA=${kr}" >> ${fname}
fi

if [ ${zflag} = 1 ]; then
    echo "Using z constraint: (z=$z; kz=$kz)"
    echo "zRestraint: RESTRAINT ARG=p.z AT=${z} KAPPA=${kz}" >> ${fname}
fi

if [ ${cflag} = 1 ]; then
    echo "Using COM constraint: (c=0; kc=${kc})"
    echo "cRestraint: RESTRAINT ARG=c.z AT=0 KAPPA=${kc}" >> ${fname}
fi

echo "PRINT ARG=r,p.z,c.z,*.bias FILE=${dirname}colvar STRIDE=1000" >> ${fname}
