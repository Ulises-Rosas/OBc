
# makefile
all: OSdiffs setupR setupPython

OSdiffs:
	if [[ `uname` == "Linux" ]]; then sed -i -e "s/sed -Ee/sed -re/g" get_checkLists.sh; fi

setupR:
	Rscript --save ./circling_r/get_packages.R
	git clone https://github.com/Ulises-Rosas/BOLD-mineR.git
	cp  BOLD-mineR/r/AuditionBarcode.v.2.R circling_r
	rm -rf BOLD-mineR
	chmod +wx ./circling_r/*
	bash ./circling_r/source --turn on

setupPython:
	chmod +x ./circling_py/*
	python3 -c "import site; print(site.getsitepackages()[0])" | xargs cp -rf ./circling_py
	sed -i -e "s/path_ssp/$${PWD//\//\\/}/g" ./circling_py/select_ids.py

unsetup:
	chmod -x ./circling_py/*
	chmod -x ./circling_r/*
	python3 -c "import site; print(site.getsitepackages()[0])" |awk '{print $$1"/circling_py"}' |xargs rm -rf
	if [[ ! -z $$(ls ./circling_py/ | grep "__pycache__") ]]; then sudo rm -rf ./circling_py/__pycache__/; fi
	rm circling_py/*-e
	rm circling_r/AuditionBarcode.v.2.R
	if [[ ! -z $$(ls ./circling_r/ | grep -e "R-e") ]]; then rm ./circling_r/*R-e; fi
