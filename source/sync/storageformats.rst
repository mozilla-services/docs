.. _sync_storageformats:

====================
Sync Storage Formats
====================

The way that Sync clients store data on a :ref:`Storage Server <server_storage>`
is defined by sets of integer storage versions. Each storage version defines
specific semantics for how clients are supposed to behave.

Global Storage Version
======================

There exists a global storage version which defines global semantics. This
global version typically defines the following:

* What special records exist on the server and what they contain
* The payload format of encrypted records on the server
* How cryptography of data works

Each Sync client is coded to support 1 or more global storage formats. If a
client encounters a storage format it doesn't support, it should *probably* stop
trying to consume data. Under no normal circumstances should a client modify
data on a server that is defined with an unknown, newer storage format. Even if
an old client wipes all server data and uploads data in its format, newer
clients may transparently upgrade to the global storage version they support.

Because changing storage formats can cause clients to not be able to use Sync
because all clients may not be upgraded to support a newer storage format at
the same time, new global storage versions are rarely introduced.

Versions 1, 2, and 3
--------------------

These were used by an old version of Sync which was deprecated in early 2011.
Historical information is `available here <https://wiki.mozilla.org/index.php?title=Labs/Weave/Developer/Crypto&oldid=200527>`_.

These versions should not be in active use and should all be upgraded to a
newer storage format.

Version 4
---------

This version initially made the switch to a new crypto model based fully on
AES. Because of a faulty implementation of the crypto, version 5 was created to
force alpha clients created with the faulty implementation to upgrade. Version
4 and version 5 are therefore practically identical.

Version 5 (Spring 2011 - Current)
---------------------------------

Version 5 replaces version 3's cryptographic model with one based purely on
AES.

A :ref:`full overview<sync_storageformat5>` is available for reference.

Historical notes are `available <https://wiki.mozilla.org/index.php?title=Services/Sync/SimplifiedCrypto&oldid=276735>`_.

Collection/Object Format Versions
=================================

The formats of unencrypted records stored on the server are also versioned.
For example, records in the *bookmarks* collection are all defined to be of
a specific type. Strictly speaking, these versions are tied to a specific
global version. However, since all storage formats to date have stored the
per-collection version in a special record, these versions in effect apply
across all global storage versions.

These versions are :ref:`fully documented<sync_objectformats>`.
