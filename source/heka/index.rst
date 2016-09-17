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
- Log-file parsing and shipping
- Statsd-like time series data

It is currently being used at Mozilla in the Marketplace and Sync infrastructures.

Resources
=========

- Heka documentation: https://hekad.readthedocs.io
- Heka binaries: https://github.com/mozilla-services/heka/releases
- Heka source: https://github.com/mozilla-services/heka
