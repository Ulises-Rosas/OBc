# OBIS/BOLD comparisons (OBc)

**Warning:** These shells only work inside the installed repository

These shells generate check list with currently accepted names of species from [OBIS database](http://iobis.org/) and these names are both compared and matched with check list with currently accepted names of species from [BOLD database](http://www.boldsystems.org/). The [WORMS database](http://www.marinespecies.org/) is used for validating species names.

Software requieremnts:

* Python3
* wget
* R

Installing OBc:

```Shell
git clone https://github.com/Ulises-Rosas/OBc.git
cd OBc
make

```
Then you can run `loop_checkLists.sh` shell and print help documentation with:

```Shell
bash loop_checkLists.sh -h
```

### Specific options

```
--list-of-taxa <filename>  
                List of taxonomic group to search for
                
--list-of-geo  <filename>  
                List of geographical to search for. This list must contain both
                Area ID and Area Name separated by a comma (e.g. 70,Peru). Area ID is
                used for mining names from OBIS database (please see: http://api.iobis.org/area) 
                and, likewise, Area Name is used for mining names from BOLD database.
                
--output-prefix <string>
                Output prefix which will be used for naming validated names from both
                OBIS and BOLD databases. By default output names are are only composed
                by Geographical parameters, taxonomic group and databases names 
                (e.i. <Area Name>_<Area ID>_<Taxa>_<obis|bold>_validated.txt).
```
### Example

There are two mock files available for testing:
```Shell
head list_*
```

```
==> list_geo <==
38,Colombia
260,Chile

==> list_invert <==
Acanthocephala
Reptilia
```
Therefore, the `loop_checkLists.sh` shell can run it with:
```Shell
bash loop_checkLists.sh --list-of-taxa list_invert --list-of-geo list_geo
```

### Output 

```Shell
ls *.txt
```

```
Chile_260_Acanthocephala_bold_validated.txt    Chile_260_Reptilia_bold_validated.txt          Colombia_38_Acanthocephala_bold_validated.txt  Colombia_38_Reptilia_bold_validated.txt
Chile_260_Acanthocephala_obis_validated.txt    Chile_260_Reptilia_obis_validated.txt          Colombia_38_Acanthocephala_obis_validated.txt  Colombia_38_Reptilia_obis_validated.txt
```


