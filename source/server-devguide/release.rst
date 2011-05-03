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

Preparing a release
===================

To cut a new release the process is:

1. increment the versions
2. update RELEASE.txt
3. tag


1. Increment the versions
:::::::::::::::::::::::::

There are two files to update:

- setup.py: the *version* options.
- Project.spec: the *version* and *unmangled_version* fields.

Extract of a spec file::

    %define version 1.0
    %define unmangled_version 1.0


2. Update RELEASE.txt
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


3. Tagging
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


