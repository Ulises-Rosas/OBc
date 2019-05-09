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

As its name suggests, this command merge results from `checklists` command by adding metadata that is already stated on filenames:

```Shell
joinfiles.py --matching _obis_
```

```
valid_name,region,subgroup,group
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
valid_name,synonyms,availability,region,subgroup,group
Dermochelys coriacea,Dermochelys coriacea,public_outside,Chile,Reptilia,Reptilia
Lepidochelys olivacea,Lepidochelys olivacea,public_outside,Chile,Reptilia,Reptilia
Caretta caretta,Caretta caretta,public_outside,Colombia,Reptilia,Reptilia
Dermochelys coriacea,Dermochelys coriacea,public_outside,Colombia,Reptilia,Reptilia
Eretmochelys imbricata,Eretmochelys imbricata,public_inside,Colombia,Reptilia,Reptilia
```

Default value of `--matching` option is `_bold_`. It is, however, stated as a matter of clearness. While default values of  column `group` is the same from `subgroup`, this can be modified with `--as` option. This is particularly usefull when merging an entire directory (i.e. using `--from` option) under a custom group:

```Shell
joinfiles.py\
   --from data/Invertebrate\
   --as Invertebrate\
   --matching _bold_ > data/invertebrate_bold.txt 

head -n 5 data/invertebrate_bold.txt
```
```
valid_name,synonyms,availability,region,subgroup,group
Aglaophamus macroura,Aglaophamus macroura,private,Chile,Annelida,Invertebrate
Aglaophamus trissophyllus,Aglaophamus trissophyllus,public_outside,Chile,Annelida,Invertebrate
Amphitrite kerguelensis,Amphitrite kerguelensis,private,Chile,Annelida,Invertebrate
Ancistrosyllis groenlandica,Ancistrosyllis groenlandica,public_outside,Chile,Annelida,Invertebrate
```
```Shell
joinfiles.py\
   --from data/Invertebrate\
   --as Invertebrate\
   --matching _obis_ > data/invertebrate_obis.txt
             
head -n 5 data/invertebrate_obis.txt
```
```
valid_name,region,subgroup,group
Abyssoninoe abyssorum,Chile,Annelida,Invertebrate
Aglaophamus foliosus,Chile,Annelida,Invertebrate
Aglaophamus macroura,Chile,Annelida,Invertebrate
Aglaophamus peruana,Chile,Annelida,Invertebrate
```

Likewise, this command can also join files from different directories while adding corresponding values for `group` column:

```Shell

joinfiles.py\
   --from data/Invertebrate data/Actinopterygii data/Elasmobranchii data/Reptilia data/Mammalia\
   --as Invertebrate Actinopterygii Elasmobranchii Reptilia Mammalia\
   --matching _bold_ > data/WholeDirectories_bold.txt
```

```Bash
joinfiles.py\
   --from data/Invertebrate data/Actinopterygii data/Elasmobranchii data/Reptilia data/Mammalia\
   --as Invertebrate Actinopterygii Elasmobranchii Reptilia Mammalia\
   --matching _obis_ > data/WholeDirectories_obis.txt
```

Each file is bigger than 400 KB and these can be found here: [data/WholeDirectories_bold.txt](https://github.com/Ulises-Rosas/OBc/blob/master/data/WholeDirectories_bold.txt), [data/WholeDirectories_obis.txt](https://github.com/Ulises-Rosas/OBc/blob/master/data/WholeDirectories_obis.txt)


## checkspps<sup>\*</sup>

Let's suppose we have the following species list called `sl_test.txt`:

```Shell
cat sl_test.txt
```

```
Caretta caretta
Dermochelys coriacea
Eretmochelys imbricata
```



This command let you perform the same analisis of [`checklist`](https://github.com/Ulises-Rosas/OBc#checklists) 

and starting from directly from a species list instead


This commmand let you perform same routine from `checklist` command but it starts from a species list and end up wi
This command let you perform both same routine from `checklist` command and end up with the same format from `joinfile.py`


This command performs same routine from  `checklist` and on their outputs `joinfiles.py`


with the file called [`sl_test.txt`]()


This command takes a species list and performs same routine from `checklist` command and returns same format from `joinfiles.py` command:


```Bash
checkspps Reptilia\
   --area-name Peru\
   --species-list sl_test.txt\
   --at Phylum
```

values of `subgroup` column are taken from a taxonomical rank of species specified with `--at` option. Remaining values for `group`, `country` are filled with the positional argument (i.e. Reptilia in above case) and `--area-name` option correspondingly.




**\*** Intermediate files generated up while running this command are the same at each run. Therefore, if this command is running in parallel, specific directory per run must be used in order to avoid intermediate file crashing. Since the following example is a single run, repo directory is used as the working directory.
