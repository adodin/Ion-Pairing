#!/bin/bash

# Makes PLUMED input files for particle pairing and interface approach applications
# Written By: Amr Dodin

# Usage Information
show_help() {
cat << EOF
Usage: ${0##*/}
Builds PLUMED input file for particle pairing and interface approach.

    -h, --help     Displays this help message and exits
    -t, --type     Type of particle N. Will use the first 
EOF
}

# Fail Function
die() {
    printf '%s\n' "$1" >&2
    exit 1
}

# Grabs List of particle IDs of specified type and assigns it to variable current_ids
get_type_ids() {
    current_ids=($(sed -n '/Atoms/,/Velo/p'  $2 | awk -v type=$1 '$3 == type { print $1 }' | sort -n))
}

# Parse Inputs
particle_ids=()
r1_ids=()
r2_ids=()
r0s=()
r_kappas=()
z_ids=()
z0s=()
z_kappas=()
plumed_file="plumed.dat"
out_file="colvar.dat"
out_freq=1000
eq_time=1
while :; do
    case $1 in
    -h|-\?|--help)
        show_help
        exit
        ;;
    -d|--data-file)
        if [ "$2" ]; then
            data_fname=$2
            shift 2
        else
            die 'ERROR: "--data-file" requires a non-empty option argument.'
        fi
        ;;
    -t|--type)
        if [ -z "$data_fname" ]; then
            die 'ERROR: "--type" used before --data-file specified.'
        fi
        if [ "$2" ]; then
            particle_type=$2
            get_type_ids $particle_type $data_fname
            found_id=false
            for id in ${current_ids[*]}; do
                if [[ ! "${particle_ids[*]}" =~ "$id " ]]; then
                    particle_ids+=("$id ")
                    found_id=true
                    shift 2
                    break
                fi
            done
            if [ "$found_id" = false ]; then
                die "ERROR: \"--type\": Particle of type ${particle_type} could not be found."
            fi
        else
            die 'ERROR: "--type" requires a non-empty option argument.'
        fi
        ;;
    -i|--id)
        if [ "$2" ]; then
            if [[ ! "${particle_ids[*]}" =~ "$2 " ]]; then
                particle_ids+=("$2 ")
            else
                die "ERROR: \"--id\" $2 already added to particle list."
            fi
            shift 2
        else
           die 'ERROR: "--id" requires a non-empty option argument.' 
        fi
        ;;
    -r|--radius-constraint)
        if [ "$5" ]; then
            if [ $2 == $3 ]; then
                die "ERROR: \"--radius-constraint\" id1 and id2 must be different. $2 and $3 provided."
            fi
            if [ $(( $2-1 )) -lt ${#particle_ids[@]} ]; then
                r1_ids+=("${particle_ids[$2-1]}")
            else
                die "ERROR: \"--radius-constraint\" id1 outside of range of particle_ids. $2 > ${#particle_ids[@]}."
            fi
            if [ $(( $3-1 )) -lt ${#particle_ids[@]} ]; then
                r2_ids+=("${particle_ids[$3-1]}")
            else
                die "ERROR: \"--radius-constraint\" id2 outside of range of particle_ids. $3 > ${#particle_ids[@]}."
            fi
            r0s+=("$4")
            r_kappas+=("$5")
            shift 5
        else
            die 'ERROR: "--radius-constraint" requires 4 option arguments (id1 id2 r0 kappa).'
        fi
        ;;
    -z|--z-constraint)
        if [ "$4" ]; then
            if [ "$2" -lt ${#particle_ids[@]} ]; then
                z_ids+=("${particle_ids[$2-1]}")
            else
                die "ERROR: \"--z-constraint\" id1 outside of range of particle_ids. $2 > ${#particle_ids[@]}."
            fi
            z0s+=("$3")
            z_kappas+=("$4")
            shift 4
        else
            die 'ERROR: "--radius-constraint" requires 4 option arguments (id1 id2 r0 kappa).'
        fi
        ;;
    -c|--com-constraint)
        if [ "$2" ]; then
            com_kappa=$2
            shift 2
        else
            die 'ERROR: "--com-constraint" requires a non-empty option argument.'
        fi
        ;;
    -p|--plumed-file)
        if [ "$2" ]; then
            plumed_file=$2
            shift 2
        else
            die 'ERROR: "--plumed-file" requires a non-empty option argument.'
        fi
        ;;
    -o|--out-file)
        if [ "$2" ]; then
            out_file=$2
            shift 2
        else
            die 'ERROR: "--out-file" requires a non-empty option argument.'
        fi
        ;;
    -f|--out-freq)
        if [ "$2" ]; then
            out_freq=$2
            shift 2
        else
            die 'ERROR: "--out-freq" requires a non-empty option argument.'
        fi
        ;;
    -e|--eq-time)
        if [ "$2" ]; then
            eq_time=$2
            shift 2
        else
            die 'ERROR: "--eq-time" requires a non-empty option argument.'
        fi
        ;;
    *)
        break
    esac
done

# Get List of All Particle ID's
if [ "$com_kappa" ]; then
    # Check if Data file specified
    if [ "$data_fname" ]; then
        all_ids=($(sed -n '/Atoms/,/Velo/p'  ../Universal/data.swm4-ndp.Na.Cl.init | awk '$1~/^[0-9]+$/ { print $1 }' | sort -n)) 

        # Remove particle_ids from all_ids
        com_ids=()
        for i in "${all_ids[@]}"; do
            if [[ ! "${particle_ids[*]}" =~ "$i " ]]; then
                com_ids+=("$i ")
            fi
        done
        com_str=`echo ${com_ids[@]/ /,}|tr -d [:space:]`
        com_str=${com_str%?}
    else
        com_str='@mdatoms'
    fi
fi

if [ "$data_fname" ]; then
    echo "Data File: $data_fname"
fi
echo "PLUMED File: $plumed_file"
echo "Output File: $out_file"
echo "Output Freq: $out_freq"
echo "Particle IDS: ${particle_ids[*]}"

echo "UNITS LENGTH=A ENERGY=kcal/mol" > $plumed_file
echo "UNITS LENGTH=A ENERGY=kcal/mol" > eq.$plumed_file
for (( i=0; i<=${#r1_ids[@]}-1; i++ )); do
    echo "r constraint $(( i+1 )):" 
    echo "id1:${r1_ids[$i]}; id2:${r2_ids[$i]}; r0=${r0s[$i]} Angstrom; kappa=${r_kappas[$i]} kCal/mol/Angstrom^2"
    echo "r$(( i+1 )): DISTANCE ATOMS=${r1_ids[$i]/ /},${r2_ids[$i]}" >> $plumed_file
    echo "r$(( i+1 ))Restraint: RESTRAINT ARG=r$(( i+1 )) AT=${r0s[$i]} KAPPA=${r_kappas[$i]}" >> $plumed_file
    echo "r$(( i+1 )): DISTANCE ATOMS=${r1_ids[$i]/ /},${r2_ids[$i]}" >> eq.$plumed_file
    echo "r$(( i+1 ))Restraint: MOVINGRESTRAINT ARG=r$(( i+1 )) AT0=${r0s[$i]} KAPPA0=0 STEP0=0 AT1=${r0s[$i]} KAPPA1=${r_kappas[$i]} STEP1=$eq_time" >> eq.$plumed_file
done

for (( i=0; i<=${#z_ids[@]}-1; i++ )); do
    echo "z constraint $(( i+1 )):" 
    echo "id:${z_ids[$i]}; z0=${z0s[$i]} Angstrom; kappa=${z_kappas[$i]} kCal/mol/Angstrom^2"
    echo "p$(( i+1 )): POSITION ATOM=${z_ids[$i]}" >> $plumed_file
    echo "z$(( i+1 ))Restraint: RESTRAINT ARG=p$(( i+1 )).z AT=${z0s[$i]} KAPPA=${z_kappas[$i]}" >> $plumed_file
    echo "p$(( i+1 )): POSITION ATOM=${z_ids[$i]}" >> eq.$plumed_file
    echo "z$(( i+1 ))Restraint: MOVINGRESTRAINT ARG=p$(( i+1 )).z AT0=${z0s[$i]} KAPPA0=0 STEP0=0 AT1=${z0s[$i]} KAPPA1=${z_kappas[$i]} STEP1=$eq_time" >> eq.$plumed_file
done

if [ "$com_kappa" ]; then
    echo "COM Constraint:"
    echo "n_COM: ${#com_ids[@]}; kappa=$com_kappa"
    echo "cAt: COM ATOMS=$com_str" >> $plumed_file
    echo "c: POSITION ATOM=cAt" >> $plumed_file
    echo "cRestraint: RESTRAINT ARG=c.z AT=0 KAPPA=$com_kappa" >> $plumed_file
    echo "PRINT ARG=r*,p*.z,c.z,*.bias FILE=$out_file STRIDE=$out_freq" >> $plumed_file
    echo "cAt: COM ATOMS=$com_str" >> eq.$plumed_file
    echo "c: POSITION ATOM=cAt" >> eq.$plumed_file
    echo "cRestraint: RESTRAINT ARG=c.z AT=0 KAPPA=$com_kappa" >> eq.$plumed_file
    echo "PRINT ARG=r*,p*.z,c.z,*.bias FILE=$out_file STRIDE=$out_freq" >> eq.$plumed_file
else 
    echo "PRINT ARG=r*,p*.z,*.bias FILE=$out_file STRIDE=$out_freq" >> $plumed_file
    echo "PRINT ARG=r*,p*.z,*.bias FILE=$out_file STRIDE=$out_freq" >> eq.$plumed_file
fi


