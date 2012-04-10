.. _releasing:

========================
Releasing an application
========================

Preparing a release
===================

This section is a summary of the release process. The rest of the chapter
explains everything in detail.

To cut a new release the process is:

1. start a release branch
2. pin the external dependencies versions
3. update RELEASE.txt
4. tag a release candidate
5. build a release and all rpms
6. fix your release !
7. backport your changes


1. Start a release branch
:::::::::::::::::::::::::

The first thing to do is to start a branch to do the releasing work.

Let's say you want to release **1.2**, create a *1.2-release* branch::

    $ hg branch 1.2-release

Go back to the default branch, then change the release to **1.3.dev1**, 
so any further change will be in the 1.3 train.

The version is located in the *.spec* file under the **version** field.
Extract of a spec file::

    %define version 1.3.dev1


::

    $ hg up default
    ... edit the spec file so version=1.3.dev1...
    $ hg ci -m 'starting the 1.3 developement'
    $ hg push -f    (-f is used to create the new branch in the central repo)

Once everything is committed, go back to the release branch::

     $ hg up 1.2-release

Change the .spec file version to 1.2 (it's probably 1.2.devX right now)


2. Pin the dependencies versions
::::::::::::::::::::::::::::::::

When you release an application, you must make sure that all the dependencies 
are pinned. If you don't do this, you can't be sure the application will be
run in stage or production with the same versions that the ones you've
tested.

This can be done in the **prod-reqs.txt** and **stage-reqs.txt** files. They
contain all externals dependencies the project should be using.

They usually have the same versions unless stage needs something specific.

Example::

    cef == 0.2
    WebOb == 1.0.7
    Paste == 1.7.5.1
    PasteDeploy == 1.3.4
    PasteScript == 1.7.3
    Mako == 0.4.1
    MarkupSafe == 0.12
    Beaker == 1.5.4
    python-memcached == 1.47
    simplejson == 2.1.6
    Routes == 1.12.3
    SQLAlchemy == 0.6.6
    MySQL-python == 1.2.3
    WSGIProxy == 0.2.2
    recaptcha-client == 1.0.6


On every release, you can decide to raise the versions to the latest
stables versions, after you've tried them.


3. Update RELEASE.txt
::::::::::::::::::::::

The :file:`RELEASE.txt` file is a high-level changelog that's used by other
teams to know what the release contains.

Each release has a section with the date, containing three parts:

- Impacts: which teams are impacted by the release (Ops, QA, Infrasec, etc)
- Dependencies: list internal dependencies and their versions.
- Relevant changes: lists relevant changes with Bugzilla numbers.

Example::


    1.2 - 2011-02-28
    ================

    Impacts:

    - Ops

    Dependencies:

    - None

    Relevant changes:

    - Bug 636294 - Prevent the automatic creation of the tables
    - now using the standalone cef lib



4. Tag the release
::::::::::::::::::

Our tags are following this scheme: "rpm-MAJOR.MINOR.[MICRO]" where
*MAJOR.MINOR[.MICRO]* is the version of the Python package.

Examples::

    $ hg tag "rpm-1.2"
    $ hg tag "rpm-1.2.1"


.. Note::

    The *rpm-* prefix is a legacy prefix we're keeping to avoid any conflict
    with the old PHP version tags.


.. _rpm-building:

5. Build the app and all RPMS
:::::::::::::::::::::::::::::

Building the app can now be done, by providing the tag value for your
app, and if needed a tag value for internal dependencies.

For example for account-portal (uses server-core), a call can look like 
this::

    $ make build_rpms SERVER_CORE=rpm-2.0 ACCOUNT_PORTAL=rpm-1.2 RPM_CHANNEL=stage

The syntax for the options is: **PROJECT_NAME=rpm-X.X**. When used,
will checkout the given project at the mentioned tag. 
The tag can be a release tag, or *tip*.

*PROJECT_NAME* refers to the name of the repository, after it has been
upper-cased and all the dashes ("-") replaced by underscores ("_").

For example, *server-core* becomes *SERVER_CORE*.

6. Fix your release
:::::::::::::::::::

Sorry but your **1.2** release is a brown bag! You need to fix the spec file
and maybe a few Python bugs.

We will use the **MICRO** version to do this.

- Increment the release to **1.2.1**
- Do your fixes
- Tag **1.2.1**
- Repeat and increment the MICRO version until the release works

7. Backport your changes
::::::::::::::::::::::::

If you did a few micro releases, check if you need to backport them to
the default branch.


More details
============


Naming convention
:::::::::::::::::

To avoid any conflict with another Python project -- even if the project
will not be released to PyPI, let's use these conventions:

- The project name should start with *MozSvc*
- Ideally a project contains a single package with a *mozsvc* prefix as well

.. Note::

    *MozSvc* is pronounced **Mozz-Vikk**, which is an ancient Irish Gaelic
    word that literally means **"Viking Mice"**.


Versioning scheme
:::::::::::::::::


Final Releases
--------------

For *final* releases, projects are versioned using the *MAJOR.MINOR* scheme.

Examples:

- 1.0
- 1.1
- 2.1

The *MINOR* part is incremented in the day-to-day work and the *MAJOR*
part is incremented on important updates. The definition of *important*
is left to the judgment of the releaser.

We don't really have any strategy here, like incrementing *MAJOR* only
on backward incompatible changes: all Python packages we use are part of a
server application and the only public facing API is documented web services 
that have their own versioning scheme.

That said, if a library is published at PyPI, it has supposedly reached
a stable state, and incrementing the *MAJOR* version should occur on backward
incompatible changes.

When a release fails in stage or prod, we can use a *MAJOR.MINOR.MICRO* 
scheme to fix it.


Development Releases
--------------------

The tip should always have a version with a *.devN* suffix. That is, the next 
version to be released, with N being an integer. Examples:

- 1.5.dev1
- 1.4.dev23


Full example
------------

Here's a full scenario of versioning usage:

- 1.2 is in production, tagged as "rpm-1.2"
- we want to push a 1.3
- we change the default branch version to 1.4.dev1
- we branch "1.3-release"
- a 1.3 is tagged there as "rpm-1.3"
- 1.3 is pushed on stage
- it's not working
- devs fix and tag 1.3.1 in the branch
- 1.3.1 is pushed on stage, it's working
- 1.3.1 is pushed in production
- it breaks !!!
- production is rolled back to 1.2
- devs fix the problems and tag 1.3.2
- 1.3.2 is pushed on stage, it's working
- 1.3.2 is pushed in production
- it works, congrats. Now working on 1.4.dev1 in tip


The Makefile
::::::::::::

Releases are driven by the :file:`Makefile` file contained in the project.

It should contain these targets:

- *build*: builds the project in-place
- *tests*: runs the tests.
- *build_rpms*: build the RPM collection. The collection must include the 
  project RPM but also all direct and indirect dependencies.
- *mock*: builds the RPMs, install them in a chroot, then make sure the
  app can be imported in Python

In more details:

The **build** target does the following:

1. install a local virtualenv
2. install MoPyTools in it
3. set the project to a specific channel (prod, dev or stage)
4. build the application and pull internal and external dependencies

The **test** target runs Nose against the project.

The **build_rpms** target generates the RPM for the project and for
all its internal and external dependencies, using **pypi2rpm**

The **mock** target calls **build_rpms** then installs everything
in a chroot using **Mock**, then runs an import. That ensures
the spec file dependencies are error free, and the Python app
main module is importable. Notice that this target is run only
under Centos5.


Here's an extract of a typical Makefile::

    APPNAME = server-key-exchange
    DEPS = server-core
    BUILDAPP = bin/buildapp
    BUILDRPMS = bin/buildrpms
    CHANNEL = dev
    RPM_CHANNEL = prod
    VIRTUALENV = virtualenv
    NOSE = bin/nosetests -s --with-xunit
    TESTS = keyexchange/tests
    INSTALL = bin/pip install

    build:
        $(VIRTUALENV) --no-site-packages --distribute .
        $(INSTALL) MoPyTools
        $(BUILDAPP) $(PYPIOPTIONS) -c $(CHANNEL) $(DEPS)

    test:
        $(NOSE) $(TESTS)

    build_rpms:
        $(BUILDRPMS) -c $(RPM_CHANNEL) $(DEPS)

    mock: build build_rpms
        mock init
        mock --install python26 python26-setuptools
        cd rpms; wget http://mrepo.mozilla.org/mrepo/5-x86_64/RPMS.mozilla-services/gunicorn-0.11.2-1moz.x86_64.rpm
        cd rpms; wget http://mrepo.mozilla.org/mrepo/5-x86_64/RPMS.mozilla/nginx-0.7.65-4.x86_64.rpm
        mock --install rpms/*
        mock --chroot "python2.6 -m keyexchange.run"


Channels
::::::::

We define three channels:

- **dev**: development channel, most dependencies are unpinned, so the latest 
  PyPI release is taken
- **prod**: all dependencies should be pinned **default one**
- **stage**: all dependencies should be pinned -- might vary from production 
  versions. This channel is most of the time the same as production but can be
  useful in case the staging environment needs to be different.


Requirement files
:::::::::::::::::

All dependencies are listed in requirement files. A requirement file is a text 
file with a list of dependencies. One per line. Each dependency can have a 
version information. The file follows Pip's standard. 
See http://www.pip-installer.org/en/latest/requirement-format.html

Example::

    cef
    WebOb == 1.0.7
    Paste
    PasteDeploy
    PasteScript
    Mako
    MarkupSafe
    Beaker
    python-memcached
    simplejson
    Routes
    SQLAlchemy <= 0.6.99
    MySQL-python
    WSGIProxy
    recaptcha-client


There should be three requirement files located at the root 
of the project, one for each channel:

1. dev-reqs.txt: requirements for the **dev channel**
2. stage-reqs.txt: requirements for the **stage channel**
3. prod-reqs.txt: requirements for the **prod channel**

stage and prod files should have *pinned* versions, since those
files will be used to build applications to be released in production.

Example::

    cef == 0.2
    WebOb == 1.0.7
    Paste == 1.7.5.1
    PasteDeploy == 1.3.4
    PasteScript == 1.7.3
    Mako == 0.4.1
    MarkupSafe == 0.12
    Beaker == 1.5.4
    python-memcached == 1.47
    simplejson == 2.1.6
    Routes == 1.12.3
    SQLAlchemy == 0.6.6
    MySQL-python == 1.2.3
    WSGIProxy == 0.2.2
    recaptcha-client == 1.0.6


When a *build* or a *build_rpms* is invoked, it receives a channel option and
picks the corresponding requirement files to decide which version to pick.
Unpinned versions will make the build process pick the latest release at PyPI.
(Even if it's not stable!)

For the *build* target the default value is *dev* and for the *build_rpms* 
option it's *prod*.

You can also force a specific channel for *build* with the **CHANNEL** variable::

    $ make build CHANNEL=prod

And for **build_rpms**, **RPM_CHANNEL**::

    $ make build RPM_CHANNEL=stage



When the channel option is provided, the Makefile will use the dependencies
list from the *CHANNEL-reqs.txt* file.




PyPI Mirrors
::::::::::::

To avoid any dependency on an external resource such as python.org during the
creation of the release, there are a few options that can be used when
running the **build** command:

- **PYPI**: a PyPI mirror index location
- **PYPIEXTRAS**: The URL of an extra location where some archives are stored.
  This is useful when your application needs a package that is not published
  at PyPI.
- **PYPISTRICT**: if this flag is set, will block any attempt to fetch from
  another host than **PYPI** or **PYPIEXTRAS**

We maintain two repositories :

1. a private mirror for PyPI at http://pypi.build.mtv1.svc.mozilla.com/simple
2. a directory that can contain extra packages at http://pypi.build.mtv1.svc.mozilla.com/extras


Example of usage::

    $ make build PYPI=http://pypi.build.mtv1.svc.mozilla.com/simple PYPIEXTRAS=http://pypi.build.mtv1.svc.mozilla.com/extras PYPISTRICT=1
    ...
    Link to http://virtualenv.openplans.org ***BLOCKED*** by --allow-hosts
    ...

In this example, packages are fetched from our PyPI mirror and our extra
repository, and the strict flag will block any attempt to get the archives from
other places. This example is a good set-up when you are working from inside
the Mozilla intranet: your application will get built with no external
resources.

If you need to upload an extra archive that does not exists at PyPI (thus is
not mirrored), make sure you have the rights to access the build box with
your SSH key and do a scp::

    $ scp archive.tgz pypi.build.mtv1.svc.mozilla.com:/var/lib/pypi/mirror/web/extras

By uploading your package to this location, make build will find it as long
as **PYPIEXTRAS** is used.
