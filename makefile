
# makefile
SHELL := /bin/bash
brc := source `which activate` OBc
n_brc := `which conda` env remove -y --name OBc

all: OSdiffs setupR setupPython start_message

xcode:
	if [[ `uname` == "Darwin" ]]; then\
        if [[  -z `xcode-select -p` ]]; then\
           echo -e "\n\033[1;32mInstalling Command Line Utilities...\033[0m\n" &&\
           xcode-select --install;fi;fi

curl: xcode
	if [[ `uname` == "Darwin" ]]; then\
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
              install ~/anaconda3/bin/conda-env /usr/bin &&\
              install ~/anaconda3/bin/activate  /usr/bin; fi; fi

	if [[ `uname` == "Darwin" ]]; then\
           if [[ -z $$(which anaconda) ]]; then\
              echo -e "\n\033[1;32mInstalling anaconda...\033[0m\n" &&\
              pushd /tmp &&\
              curl -O https://repo.anaconda.com/archive/Anaconda3-2019.03-MacOSX-x86_64.sh &&\
              md5 Anaconda3-2019.03-MacOSX-x86_64.sh &&\
              bash Anaconda3-2019.03-MacOSX-x86_64.sh -b &&\
              echo 'export PATH=$$HOME/anaconda3/bin:$$PATH' >> ~/.bash_profile &&\
              popd &&\
              install ~/anaconda3/bin/anaconda  /usr/bin &&\
              install ~/anaconda3/bin/conda     /usr/bin &&\
              install ~/anaconda3/bin/conda-env /usr/bin &&\
              install ~/anaconda3/bin/activate  /usr/bin; fi; fi

env: conda
	if [[ -z $$(conda info --envs | grep -Ee "^OBc[ ]+/") ]]; then \
           if [[ `uname` == "Linux"  ]]; then conda-env create --file obc_envL.yml; fi &&\
           if [[ `uname` == "Darwin" ]]; then conda-env create --file obc_envM.yml; fi ;\
  else\
           if [[ `uname` == "Linux"  ]]; then $(brc) && conda-env update --file obc_envL.yml; fi &&\
           if [[ `uname` == "Darwin" ]]; then $(brc) && conda-env update --file obc_envM.yml; fi; fi

OSdiffs:
	if [[ `uname` == "Linux" ]]; then sed -i -e "s/sed -Ee/sed -re/g" get_checkLists.sh; fi

check_py2: xcode
	$(brc) &&\
        if [[ `uname` == "Darwin" ]]; then\
           if [[ -z `which python2` ]]; then\
              echo -e "\n\033[1;32mInstalling python2...\033[0m\n" &&\
              if [[ -z `which brew` ]]; then\
                 echo -e "\n\033[1;32m... but installing Brew before\033[0m\n" &&\
                 ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; fi &&\
              brew install pyenv &&\
              pyenv install 2.7.5; fi; fi

check_py3:
	$(brc) &&\
        if [[ `uname` == "Linux" ]]; then\
           if [[ -z `which python3` ]]; then\
              echo -e "\n\033[1;32mInstalling python3...\033[0m\n" &&\
              if [[ ! -z `ls ~ | grep "anaconda3"` ]]; then\
                 install ~/anaconda3/bin/python3* /usr/bin; else apt-get install -y python3; fi; fi; fi

setupR: env check_py2 check_py3
	$(brc) &&\
        Rscript --save ./circling_r/get_packages.R &&\
        git clone https://github.com/Ulises-Rosas/BOLD-mineR.git &&\
        bash ./circling_r/source --turn on
	cp  BOLD-mineR/r/AuditionBarcode.v.2.R circling_r
	cp  BOLD-mineR/r/SpecimenData.R circling_r 
	rm -rf BOLD-mineR 
	chmod +wx ./circling_r/*

setupPython:
	chmod +x ./circling_py/*
	$(brc) && python3 -c "import site; print(site.getsitepackages()[0])" | xargs cp -rf ./circling_py
	
start_message:
	echo -e "\n\nAll dependencies installed. Please run to activate:\n\n\033[1;32m    source activate OBc\n\033[0m" &&\
	echo -e "And to deactivate:\n\n\033[1;32m    conda deactivate\n\033[0m"

unsetup_py: 
	$(brc) && python3 -c "import site; print(site.getsitepackages()[0])" |awk '{print $$1"/circling_py"}' |xargs rm -rf

unsetup: unsetup_py
	chmod -x ./circling_py/*
	chmod -x ./circling_r/*
	if [[ ! -z $$(ls ./circling_py/ | grep "__pycache__") ]]; then sudo rm -rf ./circling_py/__pycache__/; fi
	rm circling_r/AuditionBarcode.v.2.R
	rm circling_r/SpecimenData.R
	if [[ ! -z $$(ls ./circling_r/ | grep -e "R-e") ]]; then rm ./circling_r/*R-e; fi

unsetup_env:
	$(n_brc)
