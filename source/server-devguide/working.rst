=================
Development cycle
=================


The usual cycle to add a feature or fix a bug is:

1. Make sure there's a bug in Bugzilla.
2. Create a functional or unit-test, or both.
   Then change the code until the tests pass.
3. Ask for a review in the bug then push your changes.
4. Get ready to revert or fix.

Note that ramping up a new project is a bit specific since you can't
really follow a per-feature cycle until it has reached a certain state.



1. A reference in Bugzilla
==========================

Every planned change to the code base of a project should start by adding a
bug in `Bugzilla <http://bugzilla.mozilla.org>`_. This is the central place
where all discussions related to the changes, code reviews will happen.

Here's an example: https://bugzilla.mozilla.org/show_bug.cgi?id=631233


2. Writing the test and the change
==================================

Ideally, you should start to write a test that demonstrates the bug or
the new feature. See :ref:`testing` for more info on how to write tests.

For bugs, it's fairly easy: you need to write a test that reproduces the
exact same problem, then fix the code until the code passes.
For new features, a test that demonstrates how it works needs
to be written.

Running tests is done with the *test* target::

    $ make test


It's important to run all tests to make sure your changes are not breaking
the code base elsewhere. You won't be able to try out all possible
execution environments of course, and that's the job of the Jenkins CI server.

*make test* needs to include the tests from all the project dependencies.
That's the case when you start a fresh project with a template.


External dependencies
---------------------

In Jenkins the tests are running in an environment built from scratch
so the tests should not:

1. depend on any file that is not in the checkout
2. use the LDAP backend - or if it does, mock anything that is trying to call ldap

The test can use MySQL but the database should be configured to use sqlite
rather than MySQL, since there is no MySQL server.

MemCached can be used and if you have a specific volatile backend, it can
potentially be installed (Redis, etc.).

In any case, make sure you still have a fallback for those so anyone
that checkouts a project can run the tests without having to install a
third-party server.

Note that Mozilla production backends are specifically tested via the
functional tests that call the dev and stage clusters.


3. Ask for a review
===================

XXX



4. Revert your change
=====================

The next steps are taken care of by Jenkins, who launch a test cycle to make
sure that your change has not broken anything under every environment
your code is used in. If it happens, an email is sent at
:term:`services-builds`.

In that case you need to fix the problem immediately, and if you can't do
it immediately, you need to revert all your changes.
