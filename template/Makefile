.PHONY: test run clean dep rpm

all: test

test:
	./scripts/test.sh

clean:
	rm -rf .tnt_*

run:
	./scripts/run.sh
	
dep:
	./dep.py --meta-file=./meta.yaml --luarocks-tree=./.rocks

rpm:
	rpmbuild -ba --define="SRC_DIR ${PWD}" rpm/{{__appname__}}.spec
