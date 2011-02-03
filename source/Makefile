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
PYPI2RPM = bin/pypi2rpm.py
SERVER = dev-auth.services.mozilla.com
SCHEME = https

.PHONY: all build test build_rpm

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
	$(EZ) pypi2rpm
	$(EZ) WebTest
	$(EZ) PasteDeploy
	$(EZ) pylint

test:
	$(NOSE) $(TESTS)

build_rpms:
	rm -rf $(CURDIR)/rpms
	mkdir $(CURDIR)/rpms
	wget http://ziade.org/python-ldap-2.3.12.tar.gz
	tar -xzvf python-ldap-2.3.12.tar.gz
	cd python-ldap-2.3.12; ../$(PYTHON) setup.py --command-packages=pypi2rpm.command bdist_rpm2 --dist-dir=$(CURDIR)/rpms --python=python26 --name=python26-ldap
	rm python-ldap-2.3.12.tar.gz
	rm -rf python-ldap-2.3.12
	$(PYPI2RPM) --dist-dir=$(CURDIR)/rpms webob
	$(PYPI2RPM) --dist-dir=$(CURDIR)/rpms paste
	$(PYPI2RPM) --dist-dir=$(CURDIR)/rpms pastedeploy
	$(PYPI2RPM) --dist-dir=$(CURDIR)/rpms pastescript
	$(PYPI2RPM) --dist-dir=$(CURDIR)/rpms sqlalchemy
	$(PYPI2RPM) --dist-dir=$(CURDIR)/rpms mako
	$(PYPI2RPM) --dist-dir=$(CURDIR)/rpms routes
	$(PYPI2RPM) --dist-dir=$(CURDIR)/rpms markupsafe
	$(PYPI2RPM) --dist-dir=$(CURDIR)/rpms simplejson
	$(PYPI2RPM) --dist-dir=$(CURDIR)/rpms mysql-python
	$(PYPI2RPM) --dist-dir=$(CURDIR)/rpms python-memcached
	$(PYPI2RPM) --dist-dir=$(CURDIR)/rpms recaptcha-client
	cd deps/server-core; rm -rf build; ../../$(PYTHON) setup.py --command-packages=pypi2rpm.command bdist_rpm2 --spec-file=Services.spec --dist-dir=$(CURDIR)/rpms
	cd deps/server-storage; rm -rf build;../../$(PYTHON) setup.py --command-packages=pypi2rpm.command bdist_rpm2 --spec-file=SyncStorage.spec --binary-only --dist-dir=$(CURDIR)/rpms
	cd deps/server-reg; rm -rf build;../../$(PYTHON) setup.py --command-packages=pypi2rpm.command bdist_rpm2 --spec-file=SyncReg.spec --dist-dir=$(CURDIR)/rpms
