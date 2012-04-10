====================================
Setting up a development environment
====================================

    This section makes the assumption that you are under Mac OS X or Linux.
    A section for Windows might be added later.

Prerequisites
-------------

Setting up a development environment for Services consists of installing
those packages:

1. make (installed by default on most Linuxes)
2. the latest gcc
3. Python 2.6 (installed by default under Debuntu, *python26* under CentOS)
4. Python 2.6 headers (*python2.6-dev* under Debuntu,
   *python26-devel* under CentOS)
5. python26-profiler under Ubuntu
6. Mercurial (*mercurial* in most distros).
7. `virtualenv <http://pypi.python.org/pypi/virtualenv>`_
8. `Distribute <http://pypi.python.org/pypi/distribute>`_
9. `Flake8 <http://pypi.python.org/pypi/Flake8>`_
10. `Paste <http://pypi.python.org/pypi/Paste>`_
11. `PasteDeploy <http://pypi.python.org/pypi/PasteDeploy>`_
12. `MoPyTools <http://pypi.python.org/pypi/MoPyTools>`_

One simple way to install all tools from 7. to 12. in your environment is to
run the Distribute bootstrap script, then install MoPyTools::

    $ curl -O http://python-distribute.org/distribute_setup.py
    $ python distribute_setup.py
    $ easy_install MoPyTools


This will pull all other tools for you and install them.

.. note:

   These steps require Admin privileges since they install files
   in the global Python distribution.

Although, each project provides a *Makefile* that bootstraps this step and
installs tools 8. to 12. automatically.  So if you prefer, it should suffice
to have only virtualenv and distribute installed system-wide::

    $ curl -O http://python-distribute.org/distribute_setup.py
    $ python distribute_setup.py
    $ easy_install virtualenv


Setting up the Project Environment
----------------------------------

Once you have all the above tools installed, working on a project consists
of creating an isolated Python environment using Virtualenv and
develop in it.

Each project provides a *Makefile* that bootstraps this step,
so you should not have to do it manually.

For example, to create an environment for the Sync project, you can
run::

    $ hg clone http://hg.mozilla.org/services/server-full
    $ cd server-full
    $ make build

The code is currently developed and tested using python2.6, and it most
likely **will not work** with other versions of python.

The project *Makefile* uses the default python interpreter found on your
`$PATH`.  If your system default python version is not 2.6, you will need to
create a python2.6 virtualenv to run ``make build``.  For example::

    $ virtualenv --python=python2.6 ~/venvs/py26
    $ source ~/venvs/py26/bin/activate
    $ make build


Once the environment has been created, you can do a sanity check by running
all tests::

    $ make test



Configuring Flake8
------------------

Flake8 can be used from the command-line, by simply running it over one or 
several files::

    $ flake8 syncreg/controllers/
    syncreg/controllers/user.py:44: 'urlunparse' imported but unused
    syncreg/controllers/user.py:44: 'urlparse' imported but unused
    syncreg/controllers/user.py:49: 'Response' imported but unused
    syncreg/controllers/user.py:55: 'get_url' imported but unused
    syncreg/controllers/user.py:276: undefined name 'environ'
    syncreg/controllers/user.py:276: undefined name 'config'
    syncreg/controllers/user.py:180:8: E111 indentation is not a multiple of four
    syncreg/controllers/user.py:240:1: 'UserController.change_password' is too complex (10)
    syncreg/controllers/user.py:318:1: 'UserController.do_password_reset' is too complex (11) 


A simpler way to use it without having to think about it, is to configure 
Mercurial to call it every time you commit a change.

To use the Mercurial hook on any *commit* or *qrefresh*, change your *.hgrc* file 
like this::

    [hooks]
    commit = python:flake8.run.hg_hook
    qrefresh = python:flake8.run.hg_hook

    [flake8]
    strict = 0

If the strict option is set to 1, any warning will block the commit. When strict
is set to 0, warnings are just displayed in the standard output.

Using a non-strict mode is good enough: it will show you the issues without
blocking your commits, so you can decide what should be done.

In some case, you might need to simply silent the warnings. You can
do this with *NOQA* markers:

- all modules that starts with a *# flake8: noqa* comment line
  are skipped.

- all lines that ends with a "# NOQA" comment are skipped as well.

