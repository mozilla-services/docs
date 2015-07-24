.. _loop:

===========
Loop Server
===========

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


Documentation content
=====================

.. toctree::
   :maxdepth: 2

   apis
   tools
   statsd

You can also find the user flow in the wiki, at
https://wiki.mozilla.org/Loop/Architecture.

Resources
=========

- Server: https://github.com/mozilla-services/loop-server
