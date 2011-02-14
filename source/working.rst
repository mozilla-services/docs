=================
Development cycle
=================

Developing is done by working locally. The usual cycle is:

- make sure there's a bug in bugzilla
- create a functional or unit-test, or both
- change the code until the tests pass
- ask for a review in the bug
- push your changes
- get ready to revert or fix

A reference in Bugzilla
=======================

XXX


Tests good practices
====================

Before any push, you need to run *make test* to make sure that they are no 
failures. *make test* needs to include the tests from all the project 
dependencies --that's the case when you start a fresh project with a 
template--.


External dependencies
---------------------

In Hudson the tests are running in an environment built from scratch 
so the tests should not:

1. depend on any file that is not in the checkout
2. use the LDAP backend - or if it does, mock anything that is trying to call ldap

The test can use MySQL but the database should be configured to use sqlite
rather than MySQL, since they is not MySQL server there.

MemCached can be used and if you have a specific volatile backend, it can
potentially be installed (Redis, etc.).

In any case, make sure you still have a fallback for those so anyone
that checkouts a project can run the tests without having to install a
third-party server.

Note that Mozilla production backends are specifically tested via the 
functional tests that call the dev and stage clusters.



Revert your change
==================

The next steps are taken care of by Hudson, who launch a test cycle to make
sure that your change has not broken anything under every environment 
your code is used in. If it happens, an email is sent at 
services-build@mozilla.org.

You need in that case to fix immediatly the problem, and if you can't do
it immediatly, to revert all your changes.
