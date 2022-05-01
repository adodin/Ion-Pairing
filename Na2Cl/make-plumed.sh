#!/bin/bash

# Set Flags for each cosntraint
r1flag=0
kr1spec=0
r2flag=0
kr2spec=0
zflag=0
kzspec=0
cflag=0

while getopts r:z:c: flag
do
    case "${flag}" in
	r) if [ $r1flag = 1 ] && [ $kr1spec = 1 ] && [ $r2flag = 0 ]; then
    r2flag=1
    r2=${OPTARG}
  elif [ $r1flag = 1 ] && [ $kr1spec = 1 ] && [ $r2flag = 1 ]; then
    kr2spec=1
    kr2=${OPTARG}
  fi
  if [ $r1flag = 0 ]; then
    r1flag=1
    r1=${OPTARG}
  elif [ $r1flag = 1 ] && [ $kr1spec = 0 ]; then
    kr1spec=1
    kr1=${OPTARG}
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

if [ $r1flag = 1 ] && [ $kr1spec = 0 ]; then
  echo "ERROR: Must specify kr spring constant for r1"
  exit 1
fi

if [ $r2flag = 1 ] && [ $kr2spec = 0 ]; then
  echo "ERROR: Must specify kr spring constant for r2"
  exit 1
fi

if [ ${zflag} = 1 ] && [ ${kzspec} = 0 ]; then
  echo "ERROR: Must specify kz spring constant"
  exit 2
fi

echo "Saving PLUMED bias to: ${fname}"

cat >${fname} << EOF
UNITS LENGTH=A ENERGY=kcal/mol
r1: DISTANCE ATOMS=2045,2046
r2: DISTANCE ATOMS=2045,2047
p: POSITION ATOM=2045
cAt: COM ATOMS=1-2046
c: POSITION ATOM=cAt
EOF

if [ ${r1flag} = 1 ]; then
    echo "Using r1 constraint: (r1=$r1; kr1=$kr1)"
    echo "r1Restraint: RESTRAINT ARG=r1 AT=${r1} KAPPA=${kr1}" >> ${fname}
fi

if [ ${r2flag} = 1 ]; then
    echo "Using r2 constraint: (r2=$r2; kr2=$kr2)"
    echo "r2Restraint: RESTRAINT ARG=r2 AT=${r2} KAPPA=${kr2}" >> ${fname}
fi

if [ ${zflag} = 1 ]; then
    echo "Using z constraint: (z=$z; kz=$kz)"
    echo "zRestraint: RESTRAINT ARG=p.z AT=${z} KAPPA=${kz}" >> ${fname}
fi

if [ ${cflag} = 1 ]; then
    echo "Using COM constraint: (c=0; kc=${kc})"
    echo "cRestraint: RESTRAINT ARG=c.z AT=0 KAPPA=${kc}" >> ${fname}
fi

echo "PRINT ARG=r1,r2,p.z,c.z,*.bias FILE=${dirname}colvar STRIDE=1000" >> ${fname}
