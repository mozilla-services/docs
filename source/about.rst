.. _about:

About this Website
==================

This website is created using `Sphinx <http://sphinx.pocoo.org/>`_.

The source of this website is under version control at
https://github.com/mozilla-services/docs.

If you want to change the content of this website, changes will need to be
made to the *master* branch of the aforementioned Git repository.

This can be done one of several ways:

- Fork the repository on GitHub and create a pull request.
- Send a patch to the `services-dev@mozilla.org <https://mail.mozilla.org/listinfo/services-dev>`_
  mailing list.
- Create a Bugzilla issue at https://bugzilla.mozilla.org/ under the **Mozilla
  Services** product for the component the docs impact.

Generating Documentation
------------------------

To generate the docs from source, you'll need to obtain Sphinx along with some
extensions.

Assuming you are using Virtualenv::

   $ virtualenv sphinx-env
   $ source sphinx-env/bin/activate
   # You are now in the fresh virtualenv for Sphinx.

   # Install dependencies.
   $ pip install sphinx sphinxcontrib-seqdiag mozilla_sphinx_theme

   # Build HTML docs.
   $ make html

By default, the Makefile looks for *sphinx-build* in your *PATH*. If you have
*sphinx-build* elsewhere, just pass the path to the Makefile::

   $ make html SPHINXBUILD=/path/to/sphinx-build
