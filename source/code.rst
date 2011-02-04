===========
Code layout
===========

A minimal Services' project usually contains:

- **Makefile** and **build.py**: used to build the environment, run tests, 
  etc.
- **RPM spec**: used to build the project's RPM.
- a directory for the Python code.
- **README**: brief intro about the project
- **setup.py**: defines Distutils' options.
- **MANIFEST.in**: defines extra options for Distutils.


Paster Template
===============


You can create a new application layout by using the *services_base* Paster 
template provided by *MoPyTools*, which will ask you a few questions::

    $ paster create -t services_base MyApp
    Selected and implied templates:
    MoPyTools#services_base  A Mozilla Services application

    Variables:
    egg:      MyApp
    package:  myapp
    project:  MyApp
    Enter version (Version (like 0.1)) ['']: 0.1
    Enter description (One-line description of the project) ['']: A cool app that does it
    Enter author (Author name) ['']: Tarek
    Enter author_email (Author email) ['']: tarek@mozilla.com
    Enter url (URL of homepage (or Repository root)) ['']: http://hg.mozilla.org/services/myapp
    Creating template services_base
    ...
    Generating Application...
    ..

Once the application is generated, a default layout is created::

    $ find MyApp/
    MyApp/
    MyApp/Makefile
    MyApp/setup.py
    MyApp/README.txt
    MyApp/pylintrc
    MyApp/myapp
    MyApp/myapp/tests
    MyApp/myapp/tests/test_sample.py
    MyApp/myapp/tests/__init__.py
    MyApp/myapp/__init__.py
    MyApp/MyApp.spec
    MyApp/build.py


You can build and test that the project is ready, by going in the 
directory and running::

    $ make build test


Makefile
========

Every project should have a Makefile with these targets:

- **build**: used to build the project inplace and all its dependencies.
- **test**: used to run all tests and produce tests coverage and lint reports.
- **build_rpms**: used to build all RPMs for the project.

The **build** target can take optional arguments to define for the project
or any of its dependency that leaves in our repositories, a Mercurial tag.

For example, to build the **KeyExchange** project with the "rpm-0.1-10" tag,
and its **ServerCore** dependency with the tag "rpm-0.1-15", one may call::

    $ make build SERVER_KEYEXCHANGE=rpm-0.1.10 SERVER_CORE=rpm-0.1-15

The option name is the repository named in upper case, with the dashes ("-")
replaced by underlines ("_"). So "server-core" becomes "SERVER_CORE".

The **test** target runs the Nose test runner, and can be used to 
work on the code. It's also used by Hudson to continuously test your
project.


RPM Spec file
=============

XXX

setup.py and MANIFEST.in
========================

XXX



All Projects repositories are located in http://hg.mozilla.com/services

