==============================
Mozilla Services Documentation
==============================

DEPRECATION NOTE
==============================
This repo has been archived and the documentation is no longer maintained.
Sync and Tokenserver docs and code are in the `syncstorage-rs` GitHub repo.
You can find the repo for this service `here <https://github.com/mozilla-services/syncstorage-rs>`_ and the maintained documentation `here <https://mozilla-services.github.io/syncstorage-rs/>`_.

This repository hosts the source documentation for the "docs" site at:

  https://docs.services.mozilla.com


To build it you will need to install python (see .python-version for supported version) and virtualenv, then do the
following::

    $ make build

This should produce a "build/html" directory containing the generated HTML
documentation.

Publishing to Read The Docs
----

Ensure that the ``.readthedocs.yaml`` file is up-to-date with the `current configuration <https://docs.readthedocs.io/en/stable/config-file/v2.html>`_.
Do not specify ``sphinx``: ``configuration:`` option as this may over-ride the default Read the Docs `conf.py` file.

e.g. ensure that the following lines are commented.

.. code-block:: yaml

  # Build documentation in the "docs/" directory with Sphinx
  # sphinx:
  #   configuration: conf.py


The project is automatically monitored by Read the Docs, so any change pushed to the ``master`` branch should invoke `a build <https://readthedocs.org/projects/mozilla-services/builds/>`_. Monitor the builds to see any errors and correct as appropriate.
