.. _sync_overview:

========
Overview
========

Introduction
============

The purpose of Sync is to exchange browser data (bookmarks, history, open tabs,
passwords, add-ons, and the like) between "clients" in a manner that respects
a user's security and privacy.

Syncing is facilitated through the use of a server, where data is centrally
stored. This allows for syncing to occur without pairwise interaction between
network-connected clients.

.. graphviz::

  digraph {
    "Sync Server"
    "Client 1" -> "Sync Server"
    "Client 2" -> "Sync Server"
  }

Sync is different from most storage-in-the-cloud services in that data is
encrypted locally - that is it cannot be read by other parties - before it is
sent to the cloud. While many services encrypt data as it is being
*transmitted*, Sync keeps your data encrypted even after it has arrived at
the server.

This means that the Sync server operators can't read your data - even if they
wanted to. The only way your data can be read is if someone possesses your
secret Sync Key (sometimes referred to as a Recovery Key). This can occur if
your device is lost or hacked or if you reveal it to another party. The
important fact to note is that the Sync Key is never made available to the Sync
Server and without it, your encrypted data is statistically impossible to
recover.

That being said, the server operators do have access to some limited data. This
includes logs of when you connected and the types, number, and rough size of
items being synchronized. This type of information is "leaked" for practically
every network-connected service, so it shouldn't come as a surprise.

.. _overview_server:

The Sync Server
===============

The Sync server performs the vital role of storing data, tracking elementary
metadata, and providing authenticated access. The Sync server is effectively a
dumb shared whiteboard - a bit bucket if you will. It plays a very small role in
the actual syncing process. And, it *must* be this way: since data is encrypted
before being sent to the server, there is not much the server can do to *help*.

The Sync server infrastructure exposes a secure HTTP interface for :ref:`user
management and node assignment <reg>` as well as :ref:`storage
<server_storage>`. The storage server is actually a generic service that
isn't Sync-specific. Sync just uses it with specific semantics for how and where
to store data. These semantics are fully described at
:ref:`Sync Storage Formats <sync_storageformats>`.

Per-user access to the Sync server is protected via authentication at the HTTP
layer. This can be whatever the server operator desires. Since the bulk of
Sync's security model resides in client-side encryption (read below) and since
a Sync server is typically made available behind transport-level encryption
(like SSL/TLS), primitive forms of security such as HTTP Basic Authentication
are adequate. In fact, Mozilla's hosted Sync server that is used by default by
Firefox has used HTTP basic auth.

.. _overview_wbos:

Collections and records
=======================

The primary concept behind the Sync server's storage part is that of the
*collection*. Clients can store *objects* called *records* into *collections*.

Sync clients take their data, convert it to records, then send them to the
Sync server. Receiving data does the same, but in reverse.

Records contain basic *public* metadata, such as the time they were last
modified. This allows clients to selectively retrieve only the records that
have changed since the last sync operation.

An important observation is that the server has no notion of a "sync" as
understood by the client. From the server's perspective, there is simply a
series of HTTP requests arriving from various IP addresses performing storage
operations on a stateful backing store. The client has a well-defined sequence
of actions that take place within a notional session, which can succeed or fail
as a whole; the server does not.

Sync Clients
============

A Sync Client is an entity that talks to servers providing Sync functionality.

Sync clients come in many different flavors with different levels of support
for different features. For example, some clients may be read-only.

A specific client often targets specific versions of the storage service and
:ref:`Sync storage formats <sync_storageformats>`.
