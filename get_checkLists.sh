#!/bin/bash

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
        Area ID. This variable will be directly used for OBIS databases
    ${BROWN}-n${NC} <string>, ${BROWN}--area-name${NC} <string>
        Area name. This variable will be directly used for BOLD databases
    ${BROWN}-p${NC} <string>, ${BROWN}--output-prefix${NC} <string>
        Output prefix which will be used for naming validated names from both
        OBIS and BOLD databases 
                    ${YELLOW}[default= <TAXON>_<obis|bold>_validated.txt]${NC}
    ${BROWN}-h${NC}, ${BROWN}--help${NC}
        Show this help message and exit\n" 1>&2; exit 1; }

if [ ! -e "${p}" ];then PREFIX="TAXA" ; fi

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

uuid=$(
    curl -sL 'http://api.iobis.org/taxa/download?areaid='$AREA_ID'&scientificname='${POSITIONAL[@]} |\
        sed -Ee 's/\{ "uuid" : "([0-9A-Za-z\-]+)" \}/\1/g'
    )

status=""

while [[ $status != 'ready' ]]; do
    status=$(curl -sL "http://api.iobis.org/download/$uuid/status" |\
     sed -Ee 's/\{ "status" : "([A-Za-z ]+)" \}/\1/g')
done

wget -q  "http://api.iobis.org/download/$uuid" 
unzip -q "$uuid"
mv $uuid'.csv' ${POSITIONAL[@]}'.csv'
rm "$uuid"

cat ${POSITIONAL[@]}'.csv' |\
 grep -Ee "^[0-9]+,[A-Z][a-z]+ [a-z]+," -o |\
  sed -Ee "s/^[0-9]+,([A-Z][a-z]+ [a-z]+),/\1/g" |\
   sort -k 1 |\
    uniq > ${POSITIONAL[@]}'_obis'

rm ${POSITIONAL[@]}'.csv'


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

    echo $i

    #i="Ophelina hachaensis"
    if [[ -z $(ls . | grep "backUp_obis_bold") ]]; then

        obi_val=""

        while [[ $obi_val = "" ]]; do
            obi_val=$(python3 ./circling_py/select_ids.py -tax -type validate -string $i)
        done

        echo -e "$obi_val" >> $obi_file 
    else

        if [[ -z $(cat "backUp_obis_bold" | awk -F',' '{print $1}'| grep -Ee "$i") ]]; then

            obi_val=""

            while [[ $obi_val = "" ]]; do
                obi_val=$(python3 ./circling_py/select_ids.py -tax -type validate -string $i)
            done

            echo -e "$obi_val" >> $obi_file
            echo -e "$i,$obi_val" >> backUp_obis_bold
        else

            obi_val=$(cat "backUp_obis_bold" | grep -Ee "^$i,[A-Z][a-z]+ [a-z]+$" | awk -F',' '{print $2}')
            echo -e "$obi_val" >> $obi_file
        fi
    fi
    
done

rm ${POSITIONAL[@]}'_obis'

sort -k 1 $obi_file | uniq > $obi_file'_2'
rm $obi_file
mv $obi_file'_2' $obi_file


## BOLD mining
Rscript --vanilla ./circling_r/species_bold.R --taxa ${POSITIONAL[@]} \
 --area-name "$AREA_NAME" --output-name ${POSITIONAL[@]}'_bold'


if [[ $(cat ${POSITIONAL[@]}'_bold' | wc -l) -eq 0 ]]; then

    echo -e "\n${RED}There are not species available in BOLD by given parameters\n${NC}"
    rm ${POSITIONAL[@]}'_bold'
    #rm ${POSITIONAL[@]}'_obis'
    touch $bold_file
else

    touch $bold_file
    echo -e "\nValidating names from BOLD and storing them at: ${BROWN}"$bold_file"\n${NC}"

    IFS=$'\n'
    for j in $(cat ${POSITIONAL[@]}'_bold'); do

        echo $j
        #j="Eretmochelys imbricata"
        if [[ -z $(ls . | grep "backUp_obis_bold") ]]; then

            bold_val=""

            while [[ $bold_val = "" ]]; do

                bold_val=$(python3 ./circling_py/select_ids.py -tax -type validate -string $j)
            done

            echo -e "$bold_val" >> $bold_file 
        else

            if [[ -z $(cat "backUp_obis_bold" | awk -F',' '{print $1}'| grep -Ee "$j") ]]; then

                bold_val=""

                while [[ $bold_val = "" ]]; do

                    bold_val=$(python3 ./circling_py/select_ids.py -tax -type validate -string $j)
                done
                
                echo -e "$bold_val" >> $bold_file
                echo -e "$j,$bold_val" >> backUp_obis_bold
            else

                bold_val=$(cat "backUp_obis_bold" | grep -Ee "^$j,[A-Z][a-z]+ [a-z]+$" | awk -F',' '{print $2}')
                echo -e "$bold_val" >> $bold_file
            fi
        fi
        #python3 ./circling_py/select_ids.py -tax -type validate -string $j >> $bold_file
    done

    ## Merging BOLD results with OBIS results
    Rscript --vanilla ./circling_r/merging_tables.R \
     --original-bold ${POSITIONAL[@]}'_bold' \
      --validated-bold $bold_file \
       --validated-obis $obi_file \
        --output-name $bold_file'_2'

    rm ${POSITIONAL[@]}'_bold' 
    rm $bold_file
    mv $bold_file'_2' $bold_file
fi





