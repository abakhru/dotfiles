SHELL := /bin/bash
.DEFAULT_GOAL := help
VENV_DIR := .venv

## help
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)";echo;sed -ne"/^## /{h;s/.*//;:d" -e"H;n;s/^## //;td" -e"s/:.*//;G;s/\\n## /---/;s/\\n/ /g;p;}" ${MAKEFILE_LIST}|LC_ALL='C' sort -f|awk -F --- -v n=$$(tput cols) -v i=19 -v a="$$(tput setaf 6)" -v z="$$(tput sgr0)" '{printf"%s%*s%s ",a,-i,$$1,z;m=split($$2,w," ");l=n-i;for(j=1;j<=m;j++){l-=length(w[j])+1;if(l<= 0){l=n-i-length(w[j])-1;printf"\n%*s ",-i," ";}printf"%s ",w[j];}printf"\n";}'|more $(shell test $(shell uname) == Darwin && echo '-Xr')

## build virtualenv
venv:
	uv venv --seed python3.12
	uv pip install setuptools pip wheel poetry
	${VENV_DIR}/bin/poetry config http-basic.nexus ${NEXUS_USER} ${NEXUS_PASSWORD}
	if [ -f "poetry.toml" ]; then ${VENV_DIR}/bin/poetry install; fi
	if [ -f "requirements.txt" ]; then uv pip install -r ./requirements.txt; fi

## clean pyc files
clean-pyc:
	(for i in "*.py[co]" "[.]*cache" "*.egg*" "build" "dist*" "*test-reports" "[.]coverage*" \
	"coverage*" "o" "__pycache__"; \
	do find . -name "${i}" -exec rm -rv {} + ; done)

## clean old files
clean: clean-pyc
	docker volume prune -f || true
	docker system prune -f || true
	(cd ops/helm && rm -rf charts Chart.lock t.yaml || true)
	rm -rf junit.xml .pnpm-debug.log nohup.out .ruff_cache || true
