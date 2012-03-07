.. _sync_storageformat5:

========================
Crypto/storage format v5
========================

.. _sync_storageformat5_metaglobal:

meta/global record
==================

The ``meta/global`` record is a special record on the Sync Server that contains
general metadata to describe the state of data on the Sync Server. This state
includes things like the global storage version and the set of available
engines/collections on the server.

The ``meta/global`` record is different from other records in that it is not
encrypted. Like all other records, it is a JSON string. It has the following fields:

- **storageVersion**: Integer version of the storage format used. Clients
  look at this version to ensure they can read data on the server. Clients
  that don't understand a seen version will typically abort, assuming that
  a Sync client upgrade is available.
- **syncID**: Opaque string that changes when drastic changes happen to the
  overall data. Change of this string can cause clients to drop cached data.
  The Firefox client uses 12 randomly generated base64url characters, much
  like for WBO IDs.
- **engines**: A hash with fields of engine names and values of objects that
  contain *version* and *syncID* fields, which behave like the *storageVersion*
  and *syncID* fields on this record, but on a per-engine level.

Example
-------

::

    {
      "syncID":"7vO3Zcdu6V4I",
      "storageVersion":5,
      "engines":{
        "clients":   {"version":1,"syncID":"Re1DKzUQE2jt"},
        "bookmarks": {"version":2,"syncID":"ApPN6v8VY42s"},
        "forms":     {"version":1,"syncID":"lLnCTaQM3SPR"},
        "tabs":      {"version":1,"syncID":"G1nU87H-7jdl"},
        "history":   {"version":1,"syncID":"9Tvy_Vlb44b2"},
        "passwords": {"version":1,"syncID":"yfBi2v7PpFO2"},
        "prefs":     {"version":2,"syncID":"8eONx16GXAlp"}
      }
    }


.. _sync_storageformat5_keybundles:

Key bundles
===========

This section expands on the :ref:`Cryptography Overview
<overview_crypto>`. We provides pseudo-code and sample output of what
a Sync client implementation would do.

Sync Key
--------

The *Sync Key* is a randomly generated 128 bit sequence. In the user
interface it should be represented as 26 characters from the
"friendly" base32 alphabet with dashes after the 1st, 6th, 11th, 16th,
and 21st character. The friendly base32 alphabet uses lower case
characters and ``8`` instead of ``l`` as well as ``9`` instead of
``o``.

In pseudo-code::

  sync_key_ui = encodeBase32(sync_key).lowerCase().replace('l', '8').replace('o', '9')
  sync_key_ui_dashes = sync_key_ui.replaceRegEx(/(.{1,5})/g, "-$1");

Example::

  sync_key = XXX
  sync_key_ui = XXX
  sync_key_ui_dashes = XXX


Sync Key bundle
---------------

The *Sync Key bundle* is derived from the *Sync Key* via the SHA-256
HMAC based HKDF (c.f. `RFC 5869 <http://tools.ietf.org/html/rfc5869>`_).

In pseudo-code::

    HMAC_INPUT = "Sync-AES_256_CBC-HMAC256"
    encryption_key = HMAC-SHA256(sync_key, "" + HMAC_INPUT + username + "\x01")
    hmac_key = HMAC-SHA256(sync_key, encryption_key + HMAC_INPUT + username + "\x02")

Example::

  username = XXX
  sync_key = XXX
  encryption_key = XXX
  hmac_key = XXX

Bulk key bundles
-----------------

The *Sync Key bundle* is used to verify and decrypt the
special :ref:`crypto/keys record <sync_storageformat5_cryptokeys>`. It
contains at least the default bulk key bundle (and optionally key
bundles for specific collections). See the section on
:ref:`encrypting/decrypting records <sync_storageformat5_crypto>`
below for the actual mechanics of encrypting/decrypting records.

All other records are encrypted/signed or verified/decrypted,
respectively, using the appropriate bulk key bundle (typically the
default one).

To create a bulk key bundle, simply generate two 256 bit keys.


.. _sync_storageformat5_crypto:

Encrypting/decrypting records
=============================

XXX TODO

Example::

  cleartext: XXX
  IV: XXX
  encryption_key: XXX
  hmac_key: XXX
  ciphertext: XXX
  HMAC: XXX


.. _sync_storageformat5_cryptokeys:

crypto/keys record
==================

In storage version 5, the public/private key layer has been dropped. All bulk
keys are now stored in this one WBO. Encryption and HMAC keys are separate keys
and kept in key pairs.

Encrypting and decrypting
-------------------------

The ```crypto/keys``` WBO is encrypted and verified just like any other WBO,
except the Sync Key bundle is used instead of a bulk key bundle.

Format
------

The inner payload of the ``crypto/keys`` record contains the following fields:

- **default**: Array of length 2 containing the default key pair (encryption
  key, HMAC key).
- **collections**: Object mapping collection name to collection-specific key
  pairs which are arrays of length 2 (encryption key, hMAC key).
- **collection**: String stating the collection of the record. Currently fixed
  to "crypto".


Example
-------

::

 {"id":"keys",
  "collection":"crypto",
  "collections":{},
  "default:['dGhlc2UtYXJlLWV4YWN0bHktMzItY2hhcmFjdGVycy4=',
            'eWV0LWFub3RoZXItc2V0LW9mLTMyLWNoYXJhY3RlcnM=']}
