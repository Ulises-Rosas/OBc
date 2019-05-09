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
checklists -t list_invert -g list_geo
ls *.txt
```

```
Chile_260_Acanthocephala_bold_validated.txt    Chile_260_Reptilia_bold_validated.txt          Colombia_38_Acanthocephala_bold_validated.txt  Colombia_38_Reptilia_bold_validated.txt
Chile_260_Acanthocephala_obis_validated.txt    Chile_260_Reptilia_obis_validated.txt          Colombia_38_Acanthocephala_obis_validated.txt  Colombia_38_Reptilia_obis_validated.txt
```


## joinfiles.py

As its name suggests, this command merge results from `checklists` command by adding metadata already stated on filenames. This is mainly used to 

```Shell
joinfiles.py --matching _obis_
```

```
species,region,subgroup,group
Dermochelys coriacea,Chile,Reptilia,Reptilia
Lepidochelys olivacea,Chile,Reptilia,Reptilia
Caretta caretta,Colombia,Reptilia,Reptilia
Dermochelys coriacea,Colombia,Reptilia,Reptilia
Eretmochelys imbricata,Colombia,Reptilia,Reptilia
```

```Shell
joinfiles.py --matching _bold_
```

```
valida_name,synonyms,availability,region,subgroup,group
Dermochelys coriacea,Dermochelys coriacea,public_outside,Chile,Reptilia,Reptilia
Lepidochelys olivacea,Lepidochelys olivacea,public_outside,Chile,Reptilia,Reptilia
Caretta caretta,Caretta caretta,public_outside,Colombia,Reptilia,Reptilia
Dermochelys coriacea,Dermochelys coriacea,public_outside,Colombia,Reptilia,Reptilia
Eretmochelys imbricata,Eretmochelys imbricata,public_inside,Colombia,Reptilia,Reptilia

```

## checkspps<sup>\*</sup>

You can also perform same analises, but starting from a list of species instead of a list of taxonomical rank. Further data, however is requiered, in order to create filename.


```Shell
checklists --list-of-taxa list_invert --list-of-geo list_geo
```


**\*** Intermediate files generated up while running this command are the same at each run. Therefore, if this command is running in parallel, specific directory per run must be used in order to avoid intermediate file crashing. Since the following example is a single run, repo directory is used as the working directory.
