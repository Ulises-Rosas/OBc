
# makefile
SHELL := /bin/bash

all: OSdiffs setupR setupPython start_message

curl:
	if [[ `uname` == "Darwin" ]]; then\
	    if [[ -z $$(xcode-select -p) ]]; then\
	        echo -e "\n\033[1;32mInstalling Command Line Utilities...\033[0m\n" &&\
	        xcode-select --install;fi &&\
	    if [[ -z $$(which curl) ]]; then\
	       if [[ -z $$(which brew) ]]; then\
	          echo -e "\n\033[1;32mInstalling Brew...\033[0m\n" &&\
	          ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)";fi &&\
	        echo -e "\n\033[1;32mInstalling Curl...\033[0m\n" &&\
	        brew install curl; fi; fi 

	if [[ `uname` == "Linux" ]]; then\
	   if [[ -z $$(which curl) ]]; then\
	      echo -e "\n\033[1;32mInstalling Curl...\033[0m\n" &&\
	      apt-get update &&\
	      apt-get install -y curl; fi ; fi

conda: curl
	if [[ `uname` == "Linux" ]]; then\
	    if [[ -z $$(which anaconda) ]]; then\
	        echo -e "\n\033[1;32mInstalling anaconda...\033[0m\n" &&\
	        pushd /tmp &&\
	        curl -O https://repo.anaconda.com/archive/Anaconda3-5.2.0-Linux-x86_64.sh &&\
	        sha256sum Anaconda3-5.2.0-Linux-x86_64.sh &&\
	        bash Anaconda3-5.2.0-Linux-x86_64.sh -b &&\
	        echo 'export PATH=$$PATH:$$HOME/anaconda3/bin' >> ~/.bashrc &&\
	        popd &&\
	        install ~/anaconda3/bin/anaconda  /usr/bin &&\
	        install ~/anaconda3/bin/conda     /usr/bin &&\
	        install ~/anaconda3/bin/conda-env /usr/bin; fi; fi

	if [[ `uname` == "Darwin" ]]; then\
	    echo 'export PATH=$$HOME/anaconda3/bin:$$PATH' >> ~/.bash_profile;fi

env: conda
	if [[ -z $$(conda info --envs | grep -Ee "^OBc[ ]+/") ]]; then\
	   if [[ `uname` == "Linux"  ]]; then conda-env create --file obc_envL.yml;fi &&\
	   if [[ `uname` == "Darwin" ]]; then conda-env create --file obc_envM.yml; fi;fi

OSdiffs:
	if [[ `uname` == "Linux" ]]; then sed -i -e "s/sed -Ee/sed -re/g" get_checkLists.sh; fi

setupR:
	Rscript --save ./circling_r/get_packages.R
	git clone https://github.com/Ulises-Rosas/BOLD-mineR.git
	cp  BOLD-mineR/r/AuditionBarcode.v.2.R circling_r
	cp  BOLD-mineR/r/SpecimenData.R circling_r
	rm -rf BOLD-mineR
	chmod +wx ./circling_r/*
	bash ./circling_r/source --turn on

setupPython:
	chmod +x ./circling_py/*
	python3 -c "import site; print(site.getsitepackages()[0])" | xargs cp -rf ./circling_py
	
start_message:
	echo -e "\n\nAll dependencies installed. Please run to activate:\n\n\033[1;32m    source activate OBc\n\033[0m" &&\
	echo -e "And to deactivate:\n\n\033[1;32m    conda deactivate\n\033[0m"

unsetup:
	chmod -x ./circling_py/*
	chmod -x ./circling_r/*
	python3 -c "import site; print(site.getsitepackages()[0])" |awk '{print $$1"/circling_py"}' |xargs rm -rf
	if [[ ! -z $$(ls ./circling_py/ | grep "__pycache__") ]]; then sudo rm -rf ./circling_py/__pycache__/; fi
	rm circling_r/AuditionBarcode.v.2.R
	rm circling_r/SpecimenData.R
	if [[ ! -z $$(ls ./circling_r/ | grep -e "R-e") ]]; then rm ./circling_r/*R-e; fi
