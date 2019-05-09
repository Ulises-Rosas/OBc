#!/bin/bash
alias grep='grep --color=never'

RED='\033[0;31m'
NC='\033[0m'
LBLUE='\033[1;34m'
LGREEN='\033[1;32m'
YELLOW='\033[1;33m'
BROWN='\033[0;33m'
LPURPLE='\033[1;35m'

helping() { echo -e " 
Positional argument:
--------------------
    ${BROWN}TAXA${NC} <string>
        Species group
Optional arguments:
-------------------
    ${BROWN}-a${NC} <string>, ${BROWN}--area-id${NC} <string>
        Area ID. This variable will be directly used for OBIS databases.
    ${BROWN}-n${NC} <string>, ${BROWN}--area-name${NC} <string>
        Area name. This variable will be directly used for BOLD databases.
    ${BROWN}-l${NC} <file>,   ${BROWN}--species-list${NC} <file>
        File with a species list to search for.
    ${BROWN}-r${NC} <string>, ${BROWN}--at${NC} <string>
        Coupled with '--species-list' option and add, when used, a specific
        taxonomical rank at metadata of its output.
                    ${YELLOW}[default= Phylum]${NC}
    ${BROWN}-p${NC} <string>, ${BROWN}--output-prefix${NC} <string>
        Output prefix which will be used for naming validated names from both
        OBIS and BOLD databases. Please consider that default structure of names
        are used to downstream analyses.
                    ${YELLOW}[default= <TAXON>_<obis|bold>_validated.txt]${NC}
    ${BROWN}-h${NC},          ${BROWN}--help${NC}
        Show this help message and exit\n" 1>&2; exit 1; }

if [ ! -e "${p}" ];then PREFIX="TAXA" ; fi
if [ ! -e "${r}" ];then AT="any"; fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -a|--area-id)
    AREA_ID="$2"
    shift
    shift
    ;;
    -n|--area-name)
    AREA_NAME="$2"
    shift
    shift
    ;;
    -p|--output-prefix)
    PREFIX="$2"
    shift
    shift
    ;;
    -l|--species-list)
    SL="$2"
    shift
    shift
    ;;
    -r|--at)
    AT="$2"
    shift
    shift
    ;;
    -h|--help)
    helping
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

#POSITIONAL="Reptilia"
#AREA_ID="38"
#AREA_NAME="Colombia"

OBC_PREFIX="path_ssp"

if [[ ! -z $SL ]]; then
    
    touch backUp_obis
    touch backUp_bold

    PREFIX=$AREA_NAME'_'$AREA_ID'_'${POSITIONAL[@]}
    cat $SL > ${POSITIONAL[@]}'_obis'

    if [[ `echo $AT` =~ "any" ]]; then AT="Phylum"; fi
else

    # uuid=$(
    # curl -sL 'http://api.iobis.org/taxa/download?areaid='$AREA_ID'&scientificname='${POSITIONAL[@]} |\
    #  sed -Ee 's/\{ "uuid" : "([0-9A-Za-z\-]+)" \}/\1/g' 
    #  )
     
    #  status=""
    #  while [[ $status != 'ready' ]]; do
    #     status=$(curl -sL "http://api.iobis.org/download/$uuid/status" |\
    #      sed -Ee 's/\{ "status" : "([A-Za-z ]+)" \}/\1/g')
    #  done
    
    # wget -q  "http://api.iobis.org/download/$uuid" 
    # unzip -q "$uuid"
    # mv $uuid'.csv' ${POSITIONAL[@]}'.csv'
    # rm "$uuid"

    python3 $OBC_PREFIX'/circling_py/obis.py'\
             --areaid $AREA_ID\
             --scientificname ${POSITIONAL[@]} > ${POSITIONAL[@]}'.csv'

    # cat ${POSITIONAL[@]}'.csv' |\
    #  grep -Ee "^[0-9]+,[A-Z][a-z]+ [a-z]+," -o |\
    #   sed -Ee "s/^[0-9]+,([A-Z][a-z]+ [a-z]+),/\1/g" |\
    #    sort -k 1 |\
    #     uniq > ${POSITIONAL[@]}'_obis'

    cat ${POSITIONAL[@]}'.csv' |\
     grep -Ee "^'[A-Z][a-z]+ [a-z]+'," -o |\
      sed -Ee "s/'(.*)',/\1/g" |\
       sort -k 1 |\
        uniq > ${POSITIONAL[@]}'_obis'

    rm ${POSITIONAL[@]}'.csv'

fi


if [[ $PREFIX = "TAXA" ]]; then

    obi_file=${POSITIONAL[@]}'_obis_validated.txt'
    bold_file=${POSITIONAL[@]}'_bold_validated.txt'
    touch $obi_file
    #touch $bold_file
else

    obi_file=$PREFIX'_obis_validated.txt'
    bold_file=$PREFIX'_bold_validated.txt'
    touch $obi_file
    #touch $bold_file
fi

if [[ $(cat ${POSITIONAL[@]}'_obis' | wc -l) -eq 0 ]]; then
    echo -e "${RED}There are not species available in OBIS by given parameters${NC}"
    echo -e "${RED}Breaking the shell\n${NC}" 
    rm ${POSITIONAL[@]}'_obis'
    touch $bold_file 1>&2; exit 1; 
fi

echo -e "\nValidating names from OBIS and storing them at: ${BROWN}"$obi_file"\n${NC}"

IFS=$'\n'
for i in $(cat ${POSITIONAL[@]}'_obis'); do

    # i="Caretta caretta"

    echo $i

    if [[ -z $(cat "backUp_obis" | grep -e "^${POSITIONAL[@]},$i,") ]]; then

        touch obi_syns
        while [[ $(cat obi_syns | wc -l) -lt 1 ]]; do

            python3 $OBC_PREFIX'/circling_py/select_ids.py'\
                    --tax \
                    --type   synonyms\
                    --string "${i[@]}"\
                    --prefix "${POSITIONAL[@]}"\
                    --at     "${AT[@]}" >> obi_syns

        done

        if [[ ! -z $SL ]]; then

            Valid=$( grep -e "^${POSITIONAL[@]},$i," obi_syns | awk -F',' 'NR==1 {print $3}' )
            Rank=$(  grep -e "^${POSITIONAL[@]},$i," obi_syns | awk -F',' 'NR==1 {print $4}' )
 
            echo "${Valid[@]},${AREA_NAME[@]},${Rank[@]},${POSITIONAL[@]}" >> $obi_file
        else
            grep -e "${POSITIONAL[@]},$i," obi_syns | awk -F',' 'NR==1 {print $3}' >> $obi_file
        fi

        cat obi_syns >> backUp_obis
        rm obi_syns
    else

        if [[ ! -z $SL ]]; then

            Valid=$( cat "backUp_obis" | grep -Ee "^${POSITIONAL[@]},$i," | awk -F',' 'NR==1 {print $3}' )
            Rank=$(  cat "backUp_obis" | grep -Ee "^${POSITIONAL[@]},$i," | awk -F',' 'NR==1 {print $4}' )

            echo "${Valid[@]},${AREA_NAME[@]},${Rank[@]},${POSITIONAL[@]}" >> $obi_file

        else
            cat "backUp_obis" | grep -Ee "^${POSITIONAL[@]},$i," | awk -F',' 'NR==1 {print $3}' >> $obi_file
        fi
    fi

done

rm ${POSITIONAL[@]}'_obis'

sort -k 1 $obi_file | uniq | sed '/Check your taxon\!/d' > $obi_file'_2'
rm $obi_file
mv $obi_file'_2' $obi_file


touch $bold_file

echo -e "\nValidating names from BOLD and storing them at: ${BROWN}"$bold_file"\n${NC}"

IFS=$'\n'
for spps_valid in $(cat $obi_file); do

    ## take one validated species 
    ## then, obtain all synonyms

    ## species list case:
    if [[ ! -z $SL ]]; then 
        ## metadata
        md=','$(echo $spps_valid | cut -d ',' -f2-)
        spps_valid=$( echo $spps_valid | cut -d ',' -f1 )
        syn_patt="^${POSITIONAL[@]},.*,${spps_valid[@]},"
    else
        ## metadata
        md=""
        syn_patt="^${POSITIONAL[@]},.*,${spps_valid[@]}$"
    fi

    ####### delete!! #########
    #spps_valid="Abyla haeckeli"
    ####### delete!! #########

    echo -e "${BROWN}"$spps_valid"${NC}"

    for spps_syns in $(grep -Ee "$syn_patt" backUp_obis | awk -F',' '{print $2}'); do

        ####### delete!! #########
        # spps_syns="Anchoa nasus"
        ####### delete!! #########

        echo -e "synonym: $spps_syns"

        check_inBackUp=$(cat backUp_bold | grep -Ee "^${POSITIONAL[@]},$spps_syns," )

        if [[ -z $check_inBackUp ]]; then

            main_string_bold=""
            while [[ $main_string_bold = "" ]]; do

                main_string_bold=$( Rscript --vanilla $OBC_PREFIX'/circling_r/species_bold.R'\
                                            --taxa    "$spps_syns"\
                                            --prefix  "${POSITIONAL[@]}" )
            done

            echo $main_string_bold >> backUp_bold

            main_string_bold=$(echo $main_string_bold | sed -Ee "s/^${POSITIONAL[@]},/$spps_valid,/g")

        else

            main_string_bold=$(echo $check_inBackUp | sed -Ee "s/^${POSITIONAL[@]},/$spps_valid,/g")
        fi

        if [[ -z $(echo $main_string_bold | grep "unavailable") ]]; then

            if [[ -z $(echo $main_string_bold | grep "private") ]]; then

                if [[ -z $(echo $main_string_bold | grep -e "$AREA_NAME") ]]; then

                    echo $main_string_bold | sed -Ee "s/(^$spps_valid,$spps_syns,).*/\\1public_outside$md/g" >> $bold_file
                else

                    echo $main_string_bold | sed -Ee "s/(^$spps_valid,$spps_syns,).*/\\1public_inside$md/g" >> $bold_file
                fi
            else

                echo $main_string_bold$md >> $bold_file
            fi
        fi
    done
done

if [[ $(cat $bold_file | wc -l) -eq 0 ]]; then

    echo -e "\n${RED}There are not species available in BOLD by either given parameters or species\n${NC}"
fi

if [[ ! -z $SL ]]; then
    
    rm backUp_obis
    rm backUp_bold
fi

