.. _sync_overview:

========
Overview
========

XXX TODO WRITEME

Building blocks
===============

* HTTP
* JSON
* Crypto
* ...

XXX Crap to cut up:

The Story of Sync

= Objective =

This document is intended to provide a comprehensive guide to how the various parts of Firefox Sync -- both server and client -- interact to provide the functionality of syncing browser data between clients.

It is a somewhat technical document, but should require no in-depth knowledge. Links to more detailed API docs offer an opportunity to dig deeper.


= Introduction =

The purpose of Sync is to exchange browser data (bookmarks, history, open tabs, passwords, and the like) between 'clients' in a manner that respects a user's security and privacy. Syncing behaviors are mediated by a server, which allows for syncing to occur without pairwise interaction between network-connected clients.

We shall begin by discussing the broad structure of the server, using digressions as necessary (after all, this is a story!). We will then step through a full setup and sync, outlining the HTTP requests and other operations that the client and server perform. There will be a brief diversion into encryption at the appropriate time.

= The Sync server =

The server implements a dumb shared whiteboard, performing the vital role of storing records, tracking some elementary metadata and providing authenticated access, but otherwise playing only a small role in the actual activity of synchronizing browser data. In Firefox Sync, the clients perform the bulk of the work: generating, encrypting, and uploading records; reconciling incoming records; and updating the server accordingly. Of course, it 'must' be this way: if user data is encrypted, then the server 'cannot' help with synchronization.

The Sync server exposes a secure HTTP interface for user management, node assignment, and storage. Authentication, where applicable, is currently Basic Auth; this is a reasonable decision given the transport- and payload-level encryption used, but Bug 445757 tracks work to move to an authentication mechanism that does not involve transmission of the user's password over the wire.

== User accounts ==

Every Sync user has an account. The account is identified by email address, with a 'username' value derived from this through SHA-1, base32-encoded. For example, if a user signs up with

  john@example.com

their account -- which appears in URLs -- will be

  kismw365lo7emoxr3ohojgpild6lph4b

This account is associated with a password. The password secures access to the Sync server, as well as other sites that use the same authentication method (e.g., for Mozilla's Sync infrastructure, the Account Portal at https://account.services.mozilla.com/).

===================

The primary concept behind the Sync server's storage part is that of the 'collection'. Clients can store 'objects' (due to historical reasons, termed "Weave Basic Objects") into 'collections', and retrieve them by identifier or by metadata (e.g., modified since).

An important observation is that the server has no notion of a "sync" as understood by the client. From the server's perspective, there is simply a series of HTTP requests arriving from various IP addresses, performing ReST-ish operations on a stateful backing store. The client has a well-defined sequence of actions that take place within a notional session, which can succeed or fail as a whole; the server does not.

The URL space of the server is split as follows:

  /base/version/user/
    /storage/collection/id
    /info/collections
    /meta/global

