.. _sync_overview:

========
Overview
========

Introduction
============

The purpose of Sync is to exchange browser data (bookmarks, history,
open tabs, passwords, and the like) between "clients" in a manner that
respects a user's security and privacy. Syncing behaviors are mediated
by a server, which allows for syncing to occur without pairwise
interaction between network-connected clients.

We shall begin by discussing the broad structure of the system:
server, client, data structures, cryptography, etc. The sections after
this overview then contain the details on a full setup and sync,
including the HTTP requests and other operations that the client and
server perform, as well as the specific record formats.


.. _overview_buildingblocks:

Building blocks
===============

The Firefox Sync system is built with a lot of standard technologies
that are available or can easily be built in most environments:

* HTTP
* JSON
* Base64 and Base32 based encodings (`RFC 4648 <http://tools.ietf.org/html/rfc4648>`_)
* Strong cryptography, particularly
  - AES 256 in CBC mode with PKCS5 padding
  - SHA-1, SHA-256 HMAC
  - HMAC-based HKDF (`RFC 5869 <http://tools.ietf.org/html/rfc5869>`_)


.. _overview_server:

The Sync server
===============

The storage server implements a dumb shared whiteboard, performing the vital role of storing records, tracking some elementary metadata and providing authenticated access, but otherwise playing only a small role in the actual activity of synchronizing browser data. In Firefox Sync, the clients perform the bulk of the work: generating, encrypting, and uploading records; reconciling incoming records; and updating the server accordingly. Of course, it 'must' be this way: if user data is encrypted, then the server 'cannot' help with synchronization.

The Sync server infrastructure exposes a secure HTTP interface for :ref:`user management and node assignment <reg>` as well as :ref:`storage <server_storage>`. Authentication, where applicable, is currently Basic Auth; this is a reasonable decision given the transport- and payload-level encryption used, but `Bug 445757 <https://bugzilla.mozilla.org/show_bug.cgi?id=445757>`_ tracks work to move to an authentication mechanism that does not involve transmission of the user's password over the wire.


.. _overview_account:

User accounts
=============

Every Sync user has an account. The account is identified by email
address, with a ``username`` value derived from this through SHA-1,
lower-case base32-encoded. For example, if a user signs up with

  email = "john@example.com"

their username -- which appears in URLs and the Authorization HTTP
header -- will be

  username = encodeBase32(sha1(email.lowerCase())).lowerCase()
           = "kismw365lo7emoxr3ohojgpild6lph4b"

This account is associated with a password. The password secures access to the Sync server, as well as other sites that use the same authentication method (e.g., for Mozilla's Sync infrastructure, the Account Portal at https://account.services.mozilla.com/).


.. _overview_wbos:

Collections and records
=======================

The primary concept behind the Sync server's storage part is that of the 'collection'. Clients can store *objects* -- due to historical reasons, termed :ref:`Weave Basic Objects <storage_wbo>` -- into *collections*, and retrieve them by identifier or by metadata (e.g., modified since).

An important observation is that the server has no notion of a "sync" as understood by the client. From the server's perspective, there is simply a series of HTTP requests arriving from various IP addresses, performing REST-ish operations on a stateful backing store. The client has a well-defined sequence of actions that take place within a notional session, which can succeed or fail as a whole; the server does not.


.. _overview_crypto:

Cryptography
============

All records (WBOs) that clients store on the server are encrypted
(with the exception of the special :ref:`meta/global record
<sync_storageformat5_metaglobal>`). To encrypt or decrypt a
record, one needs the right *key bundle*. A key bundle consists of a
256 bit symmetric encryption key and a 256 bit HMAC key.

The encryption key, along with a randomly generated 16 byte IV, is
used in the AES algorithm to produce the ciphertext. The resulting
ciphertext (in its base64 form) is then "signed" with an HMAC that's
produced using the SHA-256 hashing algorithm and the HMAC key from the
corresponding key bundle. The HMAC is stored in the record.

Before a client decrypts a record, the record's HMAC **must** be
verified first. If the computed HMAC does not match the record's HMAC,
the record has either been tampered with or the client that's trying
to decrypt the record is using a different key bundle than the one
that was used when the record was uploaded. (The latter situation is
more likely as key bundle inconsistencies can easily occur due to naive
client behaviour and resulting race conditions.)

The user only has to deal with the *Sync Key* (in the UI also called
the *Recovery Key*). Here is how a client gets from the *Sync Key* to
the key bundle that's right for individual records:

1. The *Sync Key* is the master key that unlocks the user's data on
   the server. It is a 128 bit sequence that's randomly generated when
   the user first creates their account. In the user interface it
   should be represented as 26 characters from the "friendly" base32
   alphabet with dashes after the 1st, 6th, 11th, 16th, and 20th
   character.
2. The *Sync Key* is used to derive the *Sync Key bundle* which
   consists of an encryption key and an HMAC key. They are derived via
   the SHA-256 HMAC based HKDF (cf. `RFC 5869
   <http://tools.ietf.org/html/rfc5869>`_).
3. The *Sync Key bundle* is used to verify and decrypt
   the special :ref:`crypto/keys <sync_storageformat5_cryptokeys>`
   record which contains *bulk key bundles* for all other
   records. Theoretically, each collection can be associated with its
   own bulk key bundle. In practice, all records are simply encrypted
   and signed with the *default bulk key bundle*.


.. _overview_specialrecords:

Special records
===============

XXX TODO WRITEME

- meta/global
- crypto/keys
- the whole 'clients' collection
