.. _heka:

============
Heka
============

Goal
====

Heka is a high-volume logging infrastructure designed to simplify data collection and analysis across multiple input sources and output formats. It is lightweight, but can be expanded through the addition of plugins written in Go or Lua.

It can be used for:

- Application performance metrics
- Server load, memory consumption, and other machine metrics
- Database, Cache server, and other daemon metrics
- Various statsd counters
- Log-file transportion and statsd counter generation

It is currently being used at Mozilla in the Marketplace and Sync infrastructures.

Resources
=========

- Heka documentation: http://heka-docs.readthedocs.org
- Heka binaries: https://docs.services.mozilla.com/_static/binaries/hekad-0.2
- Heka source: https://github.com/mozilla-services/heka
