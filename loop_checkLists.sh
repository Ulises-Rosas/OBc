#!/bin/bash

RED='\033[0;31m'
NC='\033[0m'
LBLUE='\033[1;34m'
LGREEN='\033[1;32m'
YELLOW='\033[1;33m'
BROWN='\033[0;33m'
LPURPLE='\033[1;35m'

helping() { echo -e " 

Optional arguments:
-------------------
    ${BROWN}-t${NC} <string>, ${BROWN}--list-of-taxa${NC} <string>
        List of taxonomic group to search for
    ${BROWN}-g${NC} <string>, ${BROWN}--list-of-geo${NC} <string>
        List of geographical to search for. This list must contain both
        Area ID and Area Name separated by a comma (e.g. 70,Peru). Area ID is
        used for mining names from OBIS database and, likewise, Area Name is 
        used for mining names from BOLD database.
    ${BROWN}-p${NC} <string>, ${BROWN}--output-prefix${NC} <string>
        Output prefix which will be used for naming validated names from both
        OBIS and BOLD databases. By default output names are are only composed
        by Geographical parameters, taxonomic group and databases names 
        (e.i. <Area Name>_<Area ID>_<Taxa>_<obis|bold>_validated.txt).
                    ${YELLOW}[default= NULL]${NC}
    ${BROWN}-h${NC}, ${BROWN}--help${NC}
        Show this help message and exit\n" 1>&2; exit 1; }

if [ ! -e "${p}" ];then PREFIX="TAXA" ; fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -t|--list-of-taxa)
    LIST_TAXA="$2"
    shift
    shift
    ;;
    -g|--list-of-geo)
    LIST_GEO="$2"
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

touch backUp_obis
touch backUp_bold


IFS=$'\n'
for geo in $(cat $LIST_GEO); do

    AREA_ID=$(echo $geo | awk -F',' '{print $1}')
    AREA_NAME=$(echo $geo | awk -F',' '{print $2}')

    echo -e "${LGREEN}\nGeographical parameters: $AREA_NAME, $AREA_ID${NC}"

    for group in $(cat $LIST_TAXA); do

        if [[ $PREFIX = "TAXA" ]]; then

            echo -e "\n\t${BROWN}Working with: "$group"\n${NC}"
            bash get_checkLists.sh --area-id "$AREA_ID" --area-name "$AREA_NAME"\
                                   --output-prefix $AREA_NAME'_'$AREA_ID'_'$group $group 
        else

            echo -e "\n\t${BROWN}Working with: "$group"\n${NC}"
            bash get_checkLists.sh --area-id "$AREA_ID" --area-name "$AREA_NAME"\
                                   --output-prefix $PREFIX'_'$AREA_NAME'_'$AREA_ID'_'$group $group 
        fi
    done
done

rm backUp_obis
rm backUp_bold