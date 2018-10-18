
# makefile
all: OSdiffs setupR setupPython

OSdiffs:
	if [[ `uname` == "Linux" ]]; then sed -i -e "s/sed -Ee/sed -re/g" get_checkLists.sh; fi

setupR:
	Rscript --save ./circling_r/get_packages.R
	chmod +x ./circling_r/*.R

setupPython:
	chmod +x ./circling_py/*.py
	python3 -c "import site; print(site.getsitepackages()[0])" | xargs cp -rf ./circling_py
	sed -i -e "s/path_ssp/$${PWD//\//\\/}/g" ./circling_py/select_ids.py

unsetup:
	chmod -x ./circling_py/*
	chmod -x ./circling_r/*
	python3 -c "import site; print(site.getsitepackages()[0])" |awk '{print $$1"/circling_py"}' |xargs rm -rf
	if [[ ! -z $$(ls ./circling_py/ | grep "__pycache__") ]]; then sudo rm -rf ./circling_py/__pycache__/; fi
	rm circling_py/*-e