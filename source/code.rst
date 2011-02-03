===========
Code layout
===========

A Services' project usually contains:

- **Makefile**: used to build the environment, run tests, etc.
- **RPM spec**: used to build the project's RPM.
- a directory for the Python code.
- **README**: brief intro about the project
- **setup.py**: defines Distutils' options.
- **MANIFEST.in**: defines extra options for Distutils.
- XXX describe wsgiapp, run etc

XXX should provide a Paster Skeleton

Makefile
========

Every project should have a Makefile with these targets:

- **build**: used to build the project inplace and all its dependencies.
- **test**: used to run all tests.
- **build_rpms**: used to build all RPMs for the project.

The **build** target can take optional arguments to define for the project
or any of its dependency that leaves in our repositories, a Mercurial tag.

For example, to build the **KeyExchange** project with the "rpm-0.1-10" tag,
and its **ServerCore** dependency with the tag "rpm-0.1-15", one may call::

    $ make build SERVER_KEYEXCHANGE=rpm-0.1.10 SERVER_CORE=rpm-0.1-15

The option name is the repository named in upper case, with the dashes ("-")
replaced by underlines ("_"). So "server-core" becomes "SERVER_CORE".

Here's a sample :file:`Makefile` that may be reused:

.. literalinclude:: Makefile


XXX talk about hudson targets (coverage, lint)

RPM Spec file
=============

XXX

setup.py and MANIFEST.in
========================

XXX



All Projects repositories are located in http://hg.mozilla.com/services

