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

## Commands available

* [checklists](https://github.com/Ulises-Rosas/OBc#checklists)
* [joinfiles.py](https://github.com/Ulises-Rosas/OBc#joinfilespy)
* [checkspps](https://github.com/Ulises-Rosas/OBc#checkspps)
* [barplot](https://github.com/Ulises-Rosas/OBc#barplot)
* [sankeyplot](https://github.com/Ulises-Rosas/OBc#sankeyplot)
* [upsetplot](https://github.com/Ulises-Rosas/OBc#upsetplot)
* [auditspps](https://github.com/Ulises-Rosas/OBc#auditspps)
* [radarplot](https://github.com/Ulises-Rosas/OBc#radarplot)



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
**\*** Intermediate files generated up while running this command are the same at each run. Therefore, if this command is running in parallel, specific directory per run must be used in order to avoid intermediate file crashing. Since the following example is a single run, repo directory is used as the working directory.

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
   --matching _bold_ > invertebrate_bold.txt 

head -n 5 invertebrate_bold.txt
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
   --matching _obis_ > invertebrate_obis.txt
             
head -n 5 invertebrate_obis.txt
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
   --matching _bold_ > WholeDirectories_bold.txt
```

```Bash
joinfiles.py\
   --from data/Invertebrate data/Actinopterygii data/Elasmobranchii data/Reptilia data/Mammalia\
   --as Invertebrate Actinopterygii Elasmobranchii Reptilia Mammalia\
   --matching _obis_ > WholeDirectories_obis.txt
```

Each file is bigger than 400 KB and these can be found here: [WholeDirectories_bold.txt](https://github.com/Ulises-Rosas/OBc/blob/master/data/WholeDirectories_bold.txt), [WholeDirectories_obis.txt](https://github.com/Ulises-Rosas/OBc/blob/master/data/WholeDirectories_obis.txt)


## checkspps<sup>\*</sup>


Now, let's suppose we have a species list and not a list of taxonomical ranks instead. This species list may come from any source but OBIS database (e.g. FishBase, WoRMS, etc). `checkspps` was justly created to take a custom species list and to directly compare species into BOLD by skiping data mining steps from OBIS.


If we have a species list called [sl_test.txt](https://github.com/Ulises-Rosas/OBc/blob/master/sl_test.txt), then:

```Bash
checkspps Reptilia\
   --area-name Peru\
   --species-list sl_test.txt\
   --at Phylum
```

It will return both: [Peru_Reptilia_obis_validated.txt](https://github.com/Ulises-Rosas/OBc/blob/master/data/Peru_Reptilia_obis_validated.txt) and [Peru_Reptilia_bold_validated.txt](https://github.com/Ulises-Rosas/OBc/blob/master/data/Peru_Reptilia_bold_validated.txt). Their format are the same from `joinfiles.py` command. Values of `subgroup` column are taken from a taxonomical rank of species specified with `--at` option. Remaining values for both `group` and `country` columns are filled with the positional argument (i.e. Reptilia in above case) and `--area-name` option correspondingly.

**\*** Intermediate files generated up while running this command are the same at each run. Therefore, if this command is running in parallel, specific directory per run must be used in order to avoid intermediate file crashing. Since the following example is a single run, repo directory is used as the working directory.

## barplot

```Bash
barplot -i data/invertebrate_bold.txt
```
![](https://github.com/Ulises-Rosas/OBc/blob/master/data/img/invertebrate_bold_BarPlot.jpeg)

## upsetplot

```Bash
upsetplot -i data/bold.csv
```
![](https://github.com/Ulises-Rosas/OBc/blob/master/data/img/bold_UpsetPlot.jpeg)

## sankeyplot

```Bash
sankeyplot -b data/bold.csv -o data/obis.csv
```
![](https://github.com/Ulises-Rosas/OBc/blob/master/data/img/testSankey.jpeg)


## auditspps

This command adds both an **audition** step ([Oliveira _et al._ 2016](https://onlinelibrary.wiley.com/doi/full/10.1111/jfb.13169)) and custom taxonomical ranks (i.e. according to [WoRMS database](http://www.marinespecies.org/))to each selected specimen with public records in BOLD repository:

```Bash
auditspps -i data/bold.csv --at Phylum Order Family Genus
```
Output name is based on its input and `--at` option is used for specifying taxonomical ranks to look for.

```Bash
head bold_audited.tsv

Group	Species	Classification	sppsOnBins	N	N_Institutes	taxIDs	BINs	Phylum	Order	Family	Genus
Actinopterygii	Ablennes hians	C	Ablennes hians	14	6	13055	BOLD:AAB9824,BOLD:AAC1231,BOLD:AAC1232,BOLD:AAH7716	Chordata	Beloniformes	Belonidae	Ablennes
Actinopterygii	Abudefduf concolor	D		3	1	11481		Chordata	Perciformes	Pomacentridae	Abudefduf
Actinopterygii	Abudefduf saxatilis	E**	Abudefduf taurus,Abudefduf saxatilis	58	7	34219	BOLD:AAA7276,BOLD:AAA7275	Chordata	Perciformes	Pomacentridae	Abudefduf
Actinopterygii	Abudefduf taurus	E*	Abudefduf taurus,Abudefduf saxatilis	9	3	60120	BOLD:AAA7276	Chordata	Perciformes	Pomacentridae	Abudefduf
Actinopterygii	Abudefduf troschelii	D	Abudefduf troschelii	3	1	11480	BOLD:AAC8011	Chordata	Perciformes	Pomacentridae	Abudefduf
Actinopterygii	Acanthemblemaria balanorum	D	Acanthemblemaria balanorum	1	1	374819	BOLD:ABU5784	Chordata	Perciformes	Chaenopsidae	Acanthemblemaria
Actinopterygii	Acanthemblemaria castroi	D	Acanthemblemaria castroi	1	1	175464	BOLD:AAJ3429	Chordata	Perciformes	Chaenopsidae	Acanthemblemaria
Actinopterygii	Acanthemblemaria exilispinus	D		3	1	18107		Chordata	Perciformes	Chaenopsidae	Acanthemblemaria
Actinopterygii	Acanthemblemaria hancocki	D		2	1	18109		Chordata	Perciformes	Chaenopsidae	Acanthemblemaria
```

## radarplot

This command use radar plot to depict composition of audition performed by `auditspps`

```Bash
radarplot -i bold_audited.tsv --at Order --n 4 -l
```
![](https://github.com/Ulises-Rosas/OBc/blob/master/data/img/bold_audited_RadarPlot.jpeg)

The prior example plot radars in order according to species counts and uses `Order` category for making inner polygons. Furthermore, `--n` option indicate the maximum amount of polygons per radar and `-l` is used to include legends. There are options available to aesthetically enhance radars which can be explored with `radarplot -h`.

