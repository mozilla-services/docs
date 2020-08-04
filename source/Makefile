VIRTUALENV = virtualenv
PYTHON = bin/python
EZ = bin/easy_install
NOSE = bin/nosetests -s --with-xunit
FLAKE8 = bin/flake8
COVEROPTS = --cover-html --cover-html-dir=html --with-coverage --cover-package=syncreg,syncstorage,services
TESTS = deps/server-core/services/tests deps/server-reg/syncreg/tests deps/server-storage/syncstorage/tests
PKGS = deps/server-core/services deps/server-reg/syncreg deps/server-storage/syncstorage
COVERAGE = bin/coverage
PYLINT = bin/pylint
SERVER = dev-auth.services.mozilla.com
SCHEME = https

.PHONY: all build test

all:	build

build:
	rm -rf lib64 bin lib include
	$(VIRTUALENV) --no-site-packages --distribute .
	$(PYTHON) build.py
	$(EZ) nose
	$(EZ) coverage
	$(EZ) flake8
	$(EZ) mysql-python
	$(EZ) pygments
	$(EZ) python-memcached
	$(EZ) WebTest
	$(EZ) PasteDeploy
	$(EZ) pylint

test:
	$(NOSE) $(TESTS)
