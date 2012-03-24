.. _sync_storageformat5:

========================
Global Storage Version 5
========================

This document describes version 5 of Sync's global storage format. This
describes not only the technical details of the storage format, but also some
semantics for how clients supporting version 5 should interact with the Sync
server.

Overview
========

A single unencrypted record called the **metaglobal record** (because it exists
in the *meta* collection with the id *global*) stores essential data used to
instruct clients how to behave.

A special record called the **cryptokeys record** (because it exists in the
*crypto* collection with the id *keys*) holds encrypted keys which are used
to encrypt, decrypt, and verify all other encrypted records on the server.

.. _sync_storageformat5_metaglobal:

Metaglobal Record
=================

The ``meta/global`` record is a special record on the Sync Server that contains
general metadata to describe the state of data on the Sync Server. This state
includes things like the global storage version and the set of available
engines/collections on the server.

The ``meta/global`` record is different from other records in that it is not
encrypted.

The payload of this record is a JSON string that deserializes to an object
(i.e. a hash). This object has the following fields:

- **storageVersion**: Integer version of the global storage format used
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

Semantics and Behavior
----------------------

Clients should fetch the metaglobal record after it has been determined that a
full sync should be performed. If the metaglobal record does not exist, the
client should issue a request to delete all data from the server and then
create and upload a new metaglobal record.

In the common scenario where the metaglobal record exists, the client should
first check that the storage version from the record is supported. If it is,
great. If the storage version is older than what the client supports, the
client may choose to upgrade server data to a new storage version. Keep in
mind this may break older clients! If the storage version is newer than what
the client supports, all bets are off and the client should infer that a new
version is available and that the user should upgrade. **Clients should not
modify any data on a server if the global storage version is newer than what
is supported.**


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

Each key is Base64 encoded.

Example
-------

::

 {"id":"keys",
  "collection":"crypto",
  "collections":{},
  "default:['dGhlc2UtYXJlLWV4YWN0bHktMzItY2hhcmFjdGVycy4=',
            'eWV0LWFub3RoZXItc2V0LW9mLTMyLWNoYXJhY3RlcnM=']}

Collection Records
==================

All records in non-special collections have a common payload format.

The payload is defined as the JSON encoding of an object containing the
following fields:

- **ciphertext**: Base64 of encrypted cleartext for underlying payload.
- **IV**: Base64 encoding of IV used for encryption.
- **hmac**: Base64 encoding of HMAC for this message.

Here is an example:

::

  {
    "payload": "{\"ciphertext\":\"K5JZc7t4R2DzL6nanW+xsJMDhMZkiyRnG3ahpuz61hmFrDZu7DbsYHD77r5Eadlj\",\"IV\":\"THPKCzWVX35\\/5123ho6mJQ==\",\"hmac\":\"78ecf07c46b12ab71b769532f15977129d5fc0c121ac261bf4dda88b3329f6bd\"}",
    "id": "GJN0ojnlXXhU",
    "modified": 1332402035.78
  }

The format of the unencrypted ciphertext is defined by the collection it
resides in. See the :ref:`Object Formats<sync_objectformats>` documentation
for specifics. That being said, the cleartext is almost certainly a JSON
string representing an object. This will be assumed for the examples below.

Encryption
----------

Let's assume you have the following JSON payload to encrypt:

::

   {
     "foo": "supersecret",
     "bar": "anothersecret"
   }

Now, in pseudo-code::

   # collection_name is the name of the collection this record will be inserted
   # into. bulk_key_bundle is an object that represents the decrypted
   # crypto/keys record. The called function simply extracts the appropriate
   # key pair for the specified collection.
   key_pair = bulk_key_bundle.getKeyPair(collection_name);

   # Just some simple aliasing.
   encryption_key = key_pair.encryption_key
   hmac_key = key_pair.hmac_key

   iv = randomBytes(16)

   # cleartext is the example JSON above.
   ciphertext = AES256(cleartext, encryption_key, iv)
   ciphertext_b64 = Base64Encode(ciphertext)

   hmac = HMACSHA256(ciphertext_b64, hmac_key)

   payload = {
     "ciphertext": ciphertext_b64,
     "IV": Base64Encode(iv),
     "hmac": Base64Encode(hmac)
   }

   record.payload = JSONEncode(payload)

Decryption
----------

Decryption is just the opposite of encryption.

Let's assume we get a record from the server:

::

  {
    "payload": "{\"ciphertext\":\"K5JZc7t4R2DzL6nanW+xsJMDhMZkiyRnG3ahpuz61hmFrDZu7DbsYHD77r5Eadlj\",\"IV\":\"THPKCzWVX35\\/5123ho6mJQ==\",\"hmac\":\"78ecf07c46b12ab71b769532f15977129d5fc0c121ac261bf4dda88b3329f6bd\"}",
    "id": "GJN0ojnlXXhU",
    "modified": 1332402035.78
  }

To decrypt it::

  fields = JSONDecode(record.payload)

  # The HMAC is computed over the Base64 version of the ciphertext, so we
  # leave the encoding intact for now.
  ciphertext_b64 = fields.ciphertext

  remote_hmac = Base64Decode(fields.hmac)
  iv = Base64Decode(fields.IV)

  key_pair = bulk_key_bundle.getKeyPair(collection_name)
  encryption_key = key_pair.encryption_key
  hmac_key = key_pair.hmac_key

  local_hmac = HMACSHA256(ciphertext_b64, hmac_key)

  if local_hmac != remote_hmac:
    throw Error("HMAC verification failed.")

  ciphertext = Base64Decode(ciphertext_b64)

  cleartext = AESDecrypt(ciphertext, encryption_key, iv)

  object = JSONDecode(cleartext)
