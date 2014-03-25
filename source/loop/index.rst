.. _loop:

===========
Loop Server
===========

Goal of the Service
===================

Loop server handles interaction with provider servers (which are doing all the
WebRTC discovery). It provides a way for logged-in users to call other users,
or to be called by other people by giving them a link.

Assumptions
===========

- The Loop Server will support BrowserID only in the future, but does
  authentication with session cookies for now.

- All servers are time-synced

- The Loop server keeps a white list of origins that can do Cross-Origin
  resource sharing.


Documentation content
=====================

.. toctree::
   :maxdepth: 2

   apis
   
You can also find the user flow in the wiki, at
https://wiki.mozilla.org/Loop/Architecture.

Resources
=========

- Server: https://github.com/mozilla-services/loop-server
