.. _releasing:

========================
Releasing an application
========================

Versioning 
==========

XXX Explaining our versionning scheme here (python+rpm)


Tagging
=======

To release an application, its main repository and all its dependencies
must be properly tagged.

Our tags are following this scheme: "rpm-MAJOR-MINOR-RELEASE" where 
*MAJOR.MINOR* is the version of the Python package, as defined in the 
:file:`setup.py` file, and *RELEASE* is the RPM release version as defined
in the :file:`ProjectName.spec` file.


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


