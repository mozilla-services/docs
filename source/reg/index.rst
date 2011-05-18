========
Registry
========


Goal of the Service
===================

The reg server provides web services on the top of the authentication back-end
that can be used to:

- create or delete a new user
- change a user password or e-mail
- assign/get a storage node for a user
- return an HTML reCaptcha challenge

It's currently used by all Sync clients applications.



Documentation content
=====================

.. toctree::
   :maxdepth: 2

   apis
   history

Resources
=========

- Original wiki page: https://wiki.mozilla.org/Services/Sync/Server/API/User/1.0
- Continous Integration server: XXX
- Server: https://hg.mozilla.org/services/server-reg
- Client: Firefox 4
