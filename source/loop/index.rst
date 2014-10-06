.. _loop:

====================
Loop Server API v1.0
====================

Loop server allows firefox users to call each others via WebRTC. It is
a rendezvous API built on top of an external service provider for NAT traversal
and supplementary services.

This document is based on the current status of the server. All the examples
had been done with real calls. It doesn't reflect any future implementation and
tries to stick with the currently deployed version.

These documents describes the :ref:`HTTP APIs <http-apis>` and the
:ref:`Websockets APIs <websockets-apis>`.

.. toctree::
   :maxdepth: 3

   http
   websockets
   
You can also find the user flow in the wiki, at
https://wiki.mozilla.org/Loop/Architecture and the server source code at
https://github.com/mozilla-services/loop-server.
