====================================
Setting up a development environment
====================================

    This section make the assumption that you are under Mac OS X or Linux.
    A section for Windows might be added later.

Prerequisites
-------------

Setting up a development environment for Services consists of installing
those packages:

1. make (installed by default on most Linuces)
2. the latest gcc
3. Python 2.6 (installed by default under Debuntu, *python26* under CentOS)
4. Python 2.6 headers (*python2.6-dev* under Debuntu,
   *python26-devel* under CentOS)
5. python26-profiler under Ubuntu
6. Mercurial (*mercurial* in most distros).
7. `Distribute <http://pypi.python.org/pypi/distribute>`_
8. `virtualenv <http://pypi.python.org/pypi/virtualenv>`_
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

Once you have all these tools installed, working on a project consists
of creating an isolated Python environment using Virtualenv and
develop in it.

Although, each project provides a *Makefile* that bootstraps this step,
so you should not have to do it manually.

For example, to create an environment for the Sync project, you can
run::

    $ hg clone http://hg.mozilla.org/services/server-full
    $ cd server-full
    $ make build

Once this is done, you can do a sanity check by running all tests::

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


A more simpler way to use it without having to think about it, is to configure 
Mercurial to call it every time you commit a change.

To use the Mercurial hook on any *commit* or *qrefresh*, change your *.hgrc* file 
like this::

    [hooks]
    commit = python:flake8.hg_hook
    qrefresh = python:flake8.hg_hook

    [flake8]
    strict = 0

If strict option is set to 1, any warning will block the commit. When strict 
is set to 0, warnings are just displayed in the standard output.

Using a non-strict mode is good enough: it will show you the issues without
blocking your commits, so you can decide what should be done.

In some case, you might need to simply silent the warnings. You can
do this with *NOQA* markers:

- all modules that starts with a *# flake8: noqa* comment line
  are skipped.

- all lines that ends with a "# NOQA" comment are skipped as well.


Paster
------

All Services projects provide a built-in web server that may be used to
run a local instance.

For example in server-full, once the project is built, you can run it::

    $ bin/paster serve development.ini

This will run a server on port 5000.

