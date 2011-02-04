====================================
Setting up a development environment
====================================

    This section make the assumption that you are under Mac OS X or Linux.
    A section for Windows might be added later.

Prerequisites
-------------

Setting up a development environment for Services consists of installing
those packages:

- make (installed by default on most Linuces)
- the latest gcc
- Python 2.6 (installed by default under Debuntu, *python26* under CentOS)
- Python 2.6 headers (*python2.6-dev* under Debuntu, 
  *python26-devel* under CentOS)
- python26-profiler under Ubuntu
- Mercurial (*mercurial* in most distros).
- `Distribute <http://pypi.python.org/pypi/distribute>`_
- `MoPyTools <http://pypi.python.org/pypi/MoPyTools>`_


Once you have all these tools installed, working on a project consists
of creating an isolated Python environment using Virtualenv and
develop in it.

Although, each project provides a *Makefile* that bootstraps this step,
so you should not have to do it manually.

For example, to create an environment for the Sync project, you can 
run::

    $ hg clone http://hg.mozilla.com/services/server-full
    $ cd server-full
    $ make build

Once this is done, you can do a sanity check by running all tests::

    $ make test


Paster
------

All Services projects provide a built-in web server that may be used to 
run a local instance. 

For example in server-full, once the project is built, you can run it::

    $ bin/paster serve development.ini

This will run a server on port 5000.

