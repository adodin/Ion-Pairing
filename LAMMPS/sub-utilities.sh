#!/bin/bash 


# Parse the global (all tasks) arguments for a submit job
parse_global_args(){
    # Get Current Working Directory
    WORKINGDIR=$( pwd )/

    # Parse Required Args
    cation=$1
    echo "Cation in function $cation"
    shift
    anion=$1
    shift
    BC=$1
    shift
    replica=$1
    shift

    # Construct Data Directory Label
    DATADIR=~/DATA/Ion-Pairing/${cation}.${anion}/${BC}/replica${replica}/
    
    args_left=$@
}


announce_global_args(){
    echo "Script Directory: $WORKINGDIR"
    echo "Data Directory: $DATADIR"
    echo "Cation: $cation"
    echo "Anion: $anion"
    echo "Boundary Condition: $BC"
    echo "Replica: $replica"
    let "SEED = ${JOB_ID}"
    echo "SEED: $SEED"
    echo "Optional Arguments: $@"
}


check_cross_node_job(){
    if (( $NHOSTS > 1 )); then
            echo "ERROR: Running on more than one host."
        if [ -z ${SGE_TASK_ID} == "undefined" ]; then
            echo $@ > $JOB_NAME.${JOB_ID}.HOSTERROR
            cat $PE_HOSTFILE >> $JOB_NAME.${JOB_ID}.HOSTERROR
        else
            echo $@ > $JOB_NAME.${JOB_ID}.${SGE_TASK_ID}.HOSTERROR
            cat $PE_HOSTFILE >> $JOB_NAME.${JOB_ID}.${SGE_TASK_ID}.HOSTERROR
        fi
        exit 2
    fi
}


# Function for Array Product
prod() {      
  local mul=1 
  for i
  do 
    ((mul *= i))
  done
  echo $mul
}


parse_umbrella_bias_spec(){
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
    args_left=$@
}


construct_bias_string(){
    rBiasFlag=false
    zBiasFlag=false
    echo "==================================================="
    biasString=""
    echo "TASK: $SGE_TASK_ID"
    for (( i=0; i<=${#biasTypes[@]}-1; i++ )); do
    fDiv=$(prod ${biasNs[@]:$((i+1))})
    ind=$(((($SGE_TASK_ID-1)/$fDiv)%${biasNs[i]}))
    b0=$(bc <<< "${biasMins[i]}+${biasDs[i]}*$ind")
    if [[ (( $(echo "$b0 < 0" |bc -l) == 1 )) && ${biasTypes[i]} == z ]]; then
        bID=$(sed -E "s/^(.) /\1m / " <<< ${biasIDs[i]})
        b0=${b0//-}
    else
        bID=${biasIDs[i]}
    fi
    echo "rBiasFlag: $rBiasFlag"
    if [[ ${biasTypes[i]} = "r" ]] && [[ "${rBiasFlag}" = false ]]; then
        biasString+=" -v ${biasTypes[i]}Bias $bID $b0 ${biasKs[i]}"
        rBiasFlag=true
    elif [[ ${biasTypes[i]} = "r" ]] && [[ "${rBiasFlag}" = true ]]; then
        biasString+=" $bID $b0 ${biasKs[i]}"
    elif [[ ${biasTypes[i]} = "z" ]] && [[ ${zBiasFlag} = false ]]; then
        biasString+=" -v ${biasTypes[i]}Bias $bID $b0 ${biasKs[i]}"
        zBiasFlag=true
    elif [[ ${biasTypes[i]} = "z" ]] && [[ ${zBiasFlag} = true ]]; then
        biasString+=" $bID $b0 ${biasKs[i]}"
    fi
    echo "---------------------------------------------------"
    echo "${biasTypes[i]} Bias:"
    echo "  Biasing: ${biasIDs[i]}"
    echo "  At: $b0"
    echo "  K: ${biasKs[i]}"
    done
    echo "Bias String: ${biasString}"
    echo "==================================================="
}

clean_up_job(){
    if [ ${SGE_TASK_ID} == 'undefined' ]; then
        mv ${WORKINGDIR}/${JOB_NAME}.o${JOB_ID} ${DATADIR}.
    else
        mv ${WORKINGDIR}/${JOB_NAME}.o${JOB_ID}.${SGE_TASK_ID} ${DATADIR}.
    fi
}
