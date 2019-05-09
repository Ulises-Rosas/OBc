# OBIS/BOLD comparisons (OBc)

These shells generate check list with currently accepted names of species from [OBIS database](http://iobis.org/) and these names are both compared and matched with check list with currently accepted names of species from [BOLD database](http://www.boldsystems.org/). The [WoRMS database](http://www.marinespecies.org/) is used for validating species names.

Software requierements:
* git
* make
* Xcode (for MAC)
* anaconda3 (prefereable)

### Installing OBc

```Shell
git clone https://github.com/Ulises-Rosas/OBc.git
cd OBc
make
```
### Activating OBc

```Shell
source activate OBc
```
OBc can be deactivate with: `conda deactivate` 

### Specific options

Then you can run `checklists` shell and print help documentation with:

```Shell
checklists -h
```

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
                (i.e. <Area Name>_<Area ID>_<Taxa>_<obis|bold>_validated.txt).
```

## checklists<sup>\*</sup>

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
Therefore, the `checklists` shell can run it with:
```Shell
checklists --list-of-taxa list_invert --list-of-geo list_geo
ls *.txt
```

```
Chile_260_Acanthocephala_bold_validated.txt    Chile_260_Reptilia_bold_validated.txt          Colombia_38_Acanthocephala_bold_validated.txt  Colombia_38_Reptilia_bold_validated.txt
Chile_260_Acanthocephala_obis_validated.txt    Chile_260_Reptilia_obis_validated.txt          Colombia_38_Acanthocephala_obis_validated.txt  Colombia_38_Reptilia_obis_validated.txt
```


## checkspps<sup>\*</sup>

You can also perform same analises, but starting from a list of species instead of a list of taxonomical rank. Further data, however is requiered, in order to create filename.


```Shell
checklists --list-of-taxa list_invert --list-of-geo list_geo
```



<sup>\*</sup>Intermediate files generated up while running this command are the same at each run. Therefore, if this command is running in parallel, specific directory per run must be used in order to avoid intermediate file crashing. Since the following example is a single run, repo directory is used as the working directory.
