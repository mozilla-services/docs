======================================
Secure-Registration (Mozilla specific)
======================================

.. warning:: The SReg service is used internally in the Mozilla infrastructure
   for security reasons and it is most likely that you will never
   need it outside Mozilla.


Goal of the Service
===================

The Sreg server provides web services on the top of the authentication back-end
that can be used to:

- create a new user
- delete a user
- change a user password
- e-mail password reset codes
- delete password reset codes 

It's used by the mozilla auth backend in server-core in order to separate
system writes that can be done with the users credentials from those that
require ldap admin credentials. This provides an additional level of security
by keeping the auth credentials only on a box with limited access. The mozilla
backend is used by the Authentication server and the Account manager server.

Note that some write operations (2) are not delegated, like changing the DN &
the e-mail address of the user, so the Account manager will still bind for
writes as the user.

Sreg does not require any authentication, as it is not intended to be used
without first going through a primary gateway that performs any necessary
authentication before proxying the requests. The server must remain private to
our infrastructure with as little outside access as possible 

.. image:: /images/Sreg.png

Documentation content
=====================

.. toctree::
   :maxdepth: 2

   apis
   history

Resources
=========

- Original wiki design page/meeting notes: https://wiki.mozilla.org/Services/Sync/SRegAPI
- Continous Integration server: XXX
- Server: https://hg.mozilla.org/services/server-sreg
- Client: https://hg.mozilla.org/services/server-core/file/tip/services/auth/mozilla_sreg.py
