.. _releasing:

========================
Releasing an application
========================

Versioning
==========

Projects are versionned using the *MAJOR.MINOR* scheme. Examples:

- 1.0
- 1.1
- 2.1

The *MINOR* part is incremented in the day-to-day work and the *MAJOR*
part is incremented on important updates. The definition of *Important*
is left to the judgment of the releaser.

We don't really have any strategy here, like incrementing *MAJOR* only
on backward incompatible changes: all Python packages we use are part of a
Server application and the only public API is documented web services that
have their own versionning scheme.

That said, if a library is published at PyPI, it has supposedly reached
a stable state, and incrementing the *MAJOR* version should occur on backward
incompatible changes.

Exceptionnaly, Ops may use a *MAJOR.MINOR.MICRO* scheme if they need to.

Our RPM releases have an extra number in the spec file, the *release* number.
This number should be left to *1*. Exceptionally, Ops may raise it if they
need to patch the code without having it merged upstream.


The Makefile
============

Releases are driven by the :file:`Makefile` file contained in the project.

It should contain these targets:

- *build*: builds the project in-place
- *tests*: run the tests.
- *build_rpms*: build the RPM collection. The collection must include the 
  project RPM but also all direct and indirect dependencies.

Creating a RPM release is done via this command::

    $ make build test build_rpms


The *build_rpms* target can use the *pypi2rpm* tool in order to create RPMs.

Here's an extract of a Makefile::

    APPNAME = server-key-exchange
    DEPS = server-core
    VIRTUALENV = virtualenv
    NOSE = bin/nosetests -s --with-xunit
    TESTS = keyexchange/tests
    PYTHON = bin/python
    EZ = bin/easy_install
    PYPI2RPM = bin/pypi2rpm.py

    .PHONY: build test build_rpms 

    build:
        $(VIRTUALENV) --no-site-packages --distribute .
        $(PYTHON) build.py $(APPNAME) $(DEPS)
        $(EZ) nose
        $(EZ) pypi2rpm

    test:
        $(NOSE) $(TESTS)

    build_rpms:
        rm -rf build
        $(PYTHON) setup.py --command-packages=pypi2rpm.command bdist_rpm2 --spec-file=KeyExchange.spec --dist-dir=$(CURDIR)/rpms --binary-only
        cd deps/server-core; rm -rf build; ../../$(PYTHON) setup.py --command-packages=pypi2rpm.command bdist_rpm2 --spec-file=Services.spec --dist-dir=$(CURDIR)/rpms --binary-only
        $(PYPI2RPM) --dist-dir=$(CURDIR)/rpms webob --version=1.0
        $(PYPI2RPM) --dist-dir=$(CURDIR)/rpms paste --version=1.7.5.1
        $(PYPI2RPM) --dist-dir=$(CURDIR)/rpms pastedeploy --version=1.3.4
        $(PYPI2RPM) --dist-dir=$(CURDIR)/rpms pastescript --version=1.7.3


In this example, the **build_rpms** target generates RPMs for two Mozilla 
packages and four third-party dependencies.


Preparing a release
===================

To cut a new release the process is:

1. pin the dependencies versions
2. increment the app version
3. update RELEASE.txt
4. tag


1. Pin the dependencies versions
::::::::::::::::::::::::::::::::

When you release an application, you must make sure that all the dependencies 
are pinned. If you don't do this, you can't be sure the application will be
run in staging or production with the same versions that the ones you've
tested.

This can be done in the **build_rpms** target of the Makefile with the 
**--version** option of the pypi2rpm script::

    build_rpms:
        ...
        $(PYPI2RPM) --dist-dir=$(CURDIR)/rpms pastescript --version=1.7
        ...


On every release, you can decide to raise the versions to the latest
stables versions, after you've tried them.


2. Increment the app version
::::::::::::::::::::::::::::

There are two files to update:

- setup.py: the *version* options.
- Project.spec: the *version* and *unmangled_version* fields.

Extract of a spec file::

    %define version 1.0
    %define unmangled_version 1.0


3. Update RELEASE.txt
::::::::::::::::::::::

The :file:`RELEASE.txt` file is a high-level changelog that's used by other
teams to know what the release contains.

Each release has a section with the date, containing three parts:

- Impacts: which teams are impacted by the release (Ops, QA, Infrasec, etc)
- Dependencies: list internal dependencies and their versions.
- Relevant changes: lists relevant changes with bugzilla numbers.

Notice that the version is noted with its RPM release appended, like *-1*.

Example::


    0.2-1 - 2011-02-28
    ==================

    Impacts:

    - Ops

    Dependencies:

    - None

    Relevant changes:

    - Bug 636294 - Prevent the automatic creation of the tables
    - now using the standalone cef lib


4. Tagging
::::::::::

Our tags are following this scheme: "rpm-MAJOR-MINOR-RELEASE" where
*MAJOR.MINOR* is the version of the Python package, as defined in the
:file:`setup.py` file, and *RELEASE* is the RPM release version as defined
in the :file:`ProjectName.spec` file.

Example::

    $ hg tag "rpm-2.1-1"



.. _rpm-building:

Building the RPMs
=================

Once everything is tagged, you can run a build on the selected tags. The
*build* target accepts two variables:

- **LATEST_TAGS=1**: When used, will look for the latest release tags for
  all projects and use them.

- **PROJECT_NAME=rpm-X.X-X**: When used, will checkout the given project at
  the mentioned tag. The tag can be a release tag, or *tip*.

  *PROJECT_NAME* refers to the name of the repository, after it has been
  upper-cased and all the dashes ("-") replaced by underscores ("_").

  For example, *server-core* becomes *SERVER_CORE*.


The *build_rpms* will the create the collection of RPMs.

Examples::

    # building the Sync Server at the latest version
    $ make build build_rpms LATEST_TAGS=1

    # building the KeyEchange Server at specific tags
    $ make build build_rpms SERVER_KEY_EXCHANGE=rpm-0.2-1 SERVER_CORE=0.2-3

    # building everything on tip
    $ make build build_rpms


