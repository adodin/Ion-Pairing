#!/bin/bash

# Set Flags for each cosntraint
r1flag=0
kr1spec=0
r2flag=0
kr2spec=0
zflag=0
kzspec=0
yflag=0
kyspec=0
cflag=0

while getopts r:z:y:c: flag
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
	y) if [ $yflag = 0 ]; then
    yflag=1
    y=${OPTARG}
  else
    kyspec=1
    ky=${OPTARG}
  fi;; 
	c) cflag=1
  kc=${OPTARG};;
	esac
done

dirname=${@:$OPTIND:1}
fname=${dirname}plumed.dat
fnameeq=${dirname}eq.plumed.dat
dataname=${dirname}../data.Na2Cl.min

Cl=`sed -n '/Atoms/,/Velo/p'  ${dataname} | awk '$3 == 4 { print $1 }'|head -n 1`
Na1=`sed -n '/Atoms/,/Velo/p' ${dataname} | awk '$3 == 5 { print $1 }'|head -n 1`
Na2=`sed -n '/Atoms/,/Velo/p' ${dataname} | awk '$3 == 5 { print $1 }'|tail -n 1`

echo "Cl2- Index: ${Cl}"
echo "Na1 Index: ${Na1}"
echo "Na2 Index: ${Na2}"


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

if [ ${yflag} = 1 ] && [ ${kyspec} = 0 ]; then
  echo "ERROR: Must specify ky spring constant for cation"
  exit 3
fi

echo "Saving PLUMED bias to: ${fname}"

cat >${fname} << EOF
UNITS LENGTH=A ENERGY=kcal/mol
r1: DISTANCE ATOMS=${Cl},${Na1}
r2: DISTANCE ATOMS=${Cl},${Na2}
p: POSITION ATOM=${Cl}
p2: POSITION ATOM=${Na1}
cAt: COM ATOMS=1-$(( Cl - 1 ))
c: POSITION ATOM=cAt
EOF

cat >${fnameeq} << EOF
UNITS LENGTH=A ENERGY=kcal/mol
r1: DISTANCE ATOMS=${Cl},${Na1}
r2: DISTANCE ATOMS=${Cl},${Na2}
p: POSITION ATOM=${Cl}
p2: POSITION ATOM=${Na1}
cAt: COM ATOMS=1-$(( Cl - 1 ))
c: POSITION ATOM=cAt
EOF


if [ ${r1flag} = 1 ]; then
    echo "Using r1 constraint: (r1=$r1; kr1=$kr1)"
    echo "r1Restraint: RESTRAINT ARG=r1 AT=${r1} KAPPA=${kr1}" >> ${fname}
    echo "r1Restraint: MOVINGRESTRAINT ARG=r1 STEP0=0 AT0=${r1} KAPPA0=0.0 STEP1=5000 AT1=${r1} KAPPA1=${kr1}" >> ${fnameeq}
fi

if [ ${r2flag} = 1 ]; then
    echo "Using r2 constraint: (r2=$r2; kr2=$kr2)"
    echo "r2Restraint: RESTRAINT ARG=r2 AT=${r2} KAPPA=${kr2}" >> ${fname}
    echo "r2Restraint: MOVINGRESTRAINT ARG=r2 STEP0=0 AT0=${r2} KAPPA0=0.0 STEP1=5000 AT1=${r2} KAPPA1=${kr2}" >> ${fnameeq}
fi

if [ ${zflag} = 1 ]; then
    echo "Using z constraint: (z=$z; kz=$kz)"
    echo "zRestraint: RESTRAINT ARG=p.z AT=${z} KAPPA=${kz}" >> ${fname}
    echo "zRestraint: MOVINGRESTRAINT ARG=p.z STEP0=0 AT0=${z} KAPPA0=0.0 STEP1=5000 AT1=${z} KAPPA1=${kz}" >> ${fnameeq}
fi

if [ ${yflag} = 1 ]; then
    echo "Using y constraint: (y=$y; ky=$ky)"
    echo "yRestraint: RESTRAINT ARG=p2.z AT=${y} KAPPA=${ky}" >> ${fname}
    echo "yRestraint: MOVINGRESTRAINT ARG=y STEP0=0 AT0=${y} KAPPA0=0.0 STEP1=5000 AT1=${y} KAPPA1=${ky}" >> ${fnameeq}
fi

if [ ${cflag} = 1 ]; then
    echo "Using COM constraint: (c=0; kc=${kc})"
    echo "cRestraint: RESTRAINT ARG=c.z AT=0 KAPPA=${kc}" >> ${fname}
    echo "cRestraint: RESTRAINT ARG=c.z AT=0 KAPPA=${kc}" >> ${fnameeq}
fi

echo "PRINT ARG=r1,r2,p.z,p2.z,c.z,*.bias FILE=${dirname}colvar STRIDE=1000" >> ${fname}
echo "PRINT ARG=r1,r2,p.z,p2.z,c.z,*.bias FILE=${dirname}colvar STRIDE=1000" >> ${fnameeq}
