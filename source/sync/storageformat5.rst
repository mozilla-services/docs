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

Cryptography
============

Overview
--------

Every encrypted record (and all but one record on the server is encrypted)
is encrypted using symmetric key encryption and verified using HMAC hashing.
The symmetric encryption and HMAC verification keys are only available to
client machines: they are not transmitted to the server (at least in any form
the server can read). This means that the data on the server cannot be read by
anyone with access to the server.

The aforementioned symmetric encryption key and and HMAC key constitute what's
called a **key bundle**. Each key is 256 bits.

Individual records are encrypted with AES 256. The encryption key from a key
bundle is combined with a per-record 16 byte IV and a user's data is converted
into ciphertext. The ciphertext is *signed* with the key bundle's **HMAC key**.
The *ciphertext*, *IV*, and *HMAC value* are then uploaded to the server.

When Sync is initially configured, that client generates a random 128 bit
sequence called the **Sync Key**. This private key is used to derive a special
*key bundle* via HKDF. This is called the **Sync key bundle**. The *Sync key
bundle* is used to encrypt and decrypt a special record on the server which
holds more *key bundles*. *Key bundles* inside this record are what's used
to encrypt and decrypt all other records on the server.

Terminology
-----------

Sync Key
    128 bit random value which effectively serves as the master key to Sync.

Key Bundle
    A pair of 256 bit keys. One key is used for **symmetric encryption**. The
    other is used for **HMAC hashing**.

Sync Key Bundle
    A **Key Bundle** derived from the **Sync Key** via **HKDF**.

HKDF
    Cryptographic technique to create values derived from another.

Bulk Key Bundle
    A collection of **Key Bundles** used to secure records. This collection is
    encrypted with the **Sync Key Bundle**.

Cleartext
    The plain/clear representation of a piece of data. This is the underlying
    data that will be exchanged via Sync. It could contain personal and
    sensitive data.

Ciphertext
    The encrypted version of **Cleartext**. Ciphertext cannot be turned back
    into **Cleartext** without an **Encryption Key**.

Encryption Key
    A key in a **Key Bundle** used for symmetric encryption. This helps turn
    **Cleartext** into **Ciphertext**.

HMAC Key
    A key in a **Key Bundle** used for **HMAC hashing**.

Symmetric Encryption
    Process by which **Cleartext** is converted into **Ciphertext** and back
    again with the help of a secret key.

HMAC Hashing
    A technique used to verify that messages (**Ciphertexts**) haven't been
    tampered with. A **HMAC Key** is applied over a **Ciphertext** to produce
    a **HMAC Value.**

The Sync Key
------------

The *Sync Key* is the master private key for all of Sync. A single *Sync Key*
is shared between all clients that wish to collaborate with each other using
the server. It is important to state that the *Sync Key* should never be
transmitted to an untrusted party or stored where others could access it. This
includes inside the storage server.

The *Sync Key* is a randomly generated 128 bit sequence. Generation of this
value is left to the client. It is assumed that the chosen random sequence is
cryptographically random.

For presentation purposes, the *Sync Key* should be represented as 26
characters from the *friendly* base32 alphabet with dashes after the 1st,
6th, 11th, 16th, and 21st characters. Our *friendly* base32 alphabet uses
lower case characters and substitutes **8** for **l** and **9** for **o**.
This prevents ambiguity between **1** and **l** and **0** and **o**. In
addition, we strip off padding that may be at the end of the string.

In pseudo-code::

  sync_key = randomBytes(16)
  sync_key_ui = encodeBase32(sync_key).lowerCase().substr(0, 26).replace('l', '8').replace('o', '9')
  sync_key_dashes = sync_key_ui.replaceRegEx(/{.{1,5})/g, "-$1")

Example::

  # Generate 16 random bytes
  \xc7\x1a\xa7\xcb\xd8\xb8\x2a\x8f\xf6\xed\xa5\x5c\x39\x47\x9f\xd2

  # Base32 encode
  Y4NKPS6YXAVI75XNUVODSR472I======

  # Lower case and strip
  y4nkps6yxavi75xnuvodsr472i

  # Perform friendly string substitution (note 'o' to '9')
  y4nkps6yxavi75xnuv9dsr472i

  # Add dashes for user presentation
  y-4nkps-6yxav-i75xn-uv9ds-r472i

Sync Key Bundle
---------------

The *Sync Key Bundle* is a *key bundle* derived from the *Sync Key* via
SHA-256 HMAC-based HKDF (`RFC 5869 <http://tools.ietf.org/html/rfc5869>`_).

Remember that a *key bundle* consists of a 256 bit symmetric *encryption key*
and a *HMAC key*.

In pseudo-code::

  HMAC_INPUT = "Sync-AES_256_CBC-HMAC256"
  info = HMAC_INPUT + username

  T(1) = HMAC-SHA256(sync_key, info + 0x01)
  T(2) = HMAC-SHA256(sync_key, T(1) + info + 0x02)

  encryption_key = T(1)
  hmac = T(2)

Example::

  sync_key = \xc7\x1a\xa7\xcb\xd8\xb8\x2a\x8f\xf6\xed\xa5\x5c\x39\x47\x9f\xd2
  username = johndoe@example.com
  HMAC_INPUT = Sync-AES_256_CBC-HMAC256

  # Combine HMAC_INPUT and username to form HKDF info input.
  info = HMAC_INPUT + username
    -> "Sync-AES_256_CBC-HMAC256johndoe@example.com"

  # Perform HKDF Expansion (1)
  encryption_key = HKDF-Expand(sync_key, info + "\x01", 32)
    -> 0x8d0765430ea0d9dbd53c536c6c5c4cb639c093075ef2bd77cd30cf485138b905

  # Second round of HKDF
  hmac = HKDF-Expand(sync_key, encryption_key + info + "\x02", 32)
    -> 0xbf9e48ac50a2fcc400ae4d30a58dc6a83a7720c32f58c60fd9d02db16e406216


Record Encryption
-----------------

Individual records are encrypted using the AES algorithm + HMAC "signing" using
keys from a *key bundle*.

You take your cleartext input (which is typically a JSON string representing an
object) and feed it into AES. You Base64 encode the raw byte output of that and
feed that into HMAC SHA-256.

The AES cipher mode is CBC.

In pseudo-code::

    cleartext = "SECRET MESSAGE"
    iv = randomBytes(16)

    ciphertext = AES256(cleartext, bundle.encryptionKey, iv)
    hmac = SHA256HMAC(bundle.hmacKey, base64(ciphertext))

Example::

    encryption_key = 0xd3af449d2dc4b432b8cb5b59d40c8a5fe53b584b16469f5b44828b756ffb6a81
    hmac_key       = 0x2c5d98092d500a048d09fd01090bd0d3a4861fc8ea2438bd74a8f43be6f47f02
    cleartext = "SECRET MESSAGE"

    iv = randomBytes(16)
      -> 0x375a12d6de4ef26b735f6fccfbafff2d

    ciphertext = AES256(cleartext, encryption_key, iv)
      -> 0xc1c82acc436de625edf7feca3c9deb4c

    ciphertext_b64 = base64(ciphertext)
      -> wcgqzENt5iXt9/7KPJ3rTA==

    hmac = HMACSHA256(hmac_key, ciphertext_b64)
      -> 0xb5d1479ae2019663d6572b8e8a734e5f06c1602a0cd0becb87ca81501a08fa55

The *ciphertext*, *IV*, and *HMAC* are added to the record and uploaded to the
server.

Record Decryption
-----------------

When you obtain a record, that record will have attached its *ciphertext*,
*HMAC*, and *IV*. The client will also have a *key bundle* (with an
*encryption key* and *HMAC key*) that is associated with that record's
collection.

The first step of decryption is verifying the HMAC. If the locally-computed
HMAC does not match the HMAC on the record, the record could either have been
tampered with or it could have been encrypted with a different *key bundle*
from the one the client has. **Under no circumstances should a client try to
decrypt a record if the HMAC verification fails.**

Once HMAC verification is complete, the client decrypts the ciphertext using
the *IV* from the record and the *encryption key* from the *key bundle*.

In pseudo-code::

    ciphertext  = record.ciphertext
    iv          = record.iv
    record_hmac = record.hmac

    encryption_key = bundle.encryption_key
    hmac_key       = bundle.hmac_key

    local_hmac = HMACSHA256(hmac_key, base64(ciphertext))

    if local_hmac != record_hmac:
      throw Error("HMAC verification failed.")

    cleartext = AESDecrypt(ciphertext, encryption_key, iv)

Example::

    TODO

New Account Bootstrap
---------------------

When a new Sync account is initially configured or when an existing Sync
account is reset, we perform an initial bootstrap of the cryptographic
components.

1. The *Sync Key* is generated.
2. The *Sync key bundle* is derived from the *Sync Key*.
3. New *key bundles* are created.
4. The new *key bundles* are assembled into a *bulk key bundle*/record and
   uploaded to the server after being encrypted by the *Sync key bundle*.

At this point, the client is bootstrapped from a cryptography perspective.


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

In Protocol 1.5, an additional field is present:

- **declined**: engines that are not present in **engines**, and are not present
  in this array, can be presumed to be neither enabled nor explicitly declined.
  If a user has explicitly declined an engine, rather than e.g., not having the
  option due to missing functionality on the client, then it should be added to
  this list in the uploaded meta/global record.
  No engine should be present in both **engines** and **declined**; if an error
  results in this situation, **engines** takes precedent.

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
        "prefs":     {"version":2,"syncID":"8eONx16GXAlp"}
      },
      "declined": ["passwords"]
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
  pairs which are arrays of length 2 (encryption key, HMAC key).
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
