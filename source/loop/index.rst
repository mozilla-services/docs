.. _loop:

====================
Loop Server API v1.0
====================

Goal of the Service
===================

Loop server allows firefox users to call each others via WebRTC. It is
a rendezvous API built on top of an external service provider for NAT traversal
and supplementary services.

Assumptions
===========

- The Loop Server supports BrowserID authentication using FxA
  certificates and MSISDN certificates. 
  It uses it on the /register endpoint to create an Hawk session.

- All servers are time-synced

- The Loop server keeps a white list of origins that can do Cross-Origin
  resource sharing.


This document is based on the current status of the server. All the examples
had been done with real calls. It doesn't reflect any future implementation and
tries to stick with the currently deployed version.

This document describes the :ref:`HTTP APIs <http-apis>` and the :ref:`Websockets APIs <websockets-apis>`.

Documentation content
=====================

.. toctree::
   :maxdepth: 3

   http
   websocket
   
You can also find the user flow in the wiki, at
https://wiki.mozilla.org/Loop/Architecture.

Resources
=========

- Server source code: https://github.com/mozilla-services/loop-server
