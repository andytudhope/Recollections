.PHONY: make_env test lint


env:
	python3 -m venv env


init: make_env 
	source ./env/bin/activate; \
	pip install --upgrade pip; \
	pip install -r requirements.txt; \

test:
	source ./env/bin/activate; \
	pytest; \

lint:
	source ./env/bin/activate; \
	flake8 tests; \
