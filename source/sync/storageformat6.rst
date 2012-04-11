.. _sync_storageformat6:

========================
Global Storage Version 6
========================

.. attention::

  This document is a proposal. It will likely change.

This document describes version 6 of Sync's global storage format. This
describes not only the technical details of the storage format, but also some
semantics for how clients supporting version 6 should interact with the Sync
server.

Cryptographic Model
===================

All data on the server (with the exception of a single record containing
non-private metadata used to help clients perform sanity checking) is encrypted
on the client using AES symmetric encryption with 256 bit keys. Encrypted data
is secured against tampering by employing HMAC-SHA256 hashing.

The cryptographic model frequently relies on pairs of 256 bit keys. One key is
used for AES symmetric encryption; the other for HMAC verification. We refer to
such a pair of keys as a **Key Bundle**.

Data on the server is organized into collections (e.g. *history*, *bookmarks*).
Every collection has a single **Key Bundle** associated with it. We refer to
a **Key Bundle** that is affiliated with a collection as a **Collection Key
Bundle**. A single **Collection Key Bundle** is used to perform cryptographic
operations on every record in the collection to which it is associated.

It is recommended, but not technically required, that each **Collection Key Bundle**
be associated with at most a single collection.

Special records on the server hold mappings of collection names to their
respective **Collection Key Bundles**. The **Collection Key Bundles** are
encrypted using another higher-level **Key Bundle** before they are stored
on the server. We refer to these higher-level **Key Bundles** as
**Key-Encrypting Key Bundles**. And, the entity that holds the mapping to
**Collection Key Bundles** is referred to as a **crypto record** (because it
is a record stored in the *crypto* collection).

In the simple case, we have a single **Key-Encrypting Key Bundle** used to
encrypt the collection of all **Collection Key Bundles**. Each **Collection
Key Bundle** is used to encrypt every record in the collection to which it is
associated. In other words, we have a master key used to unlock other keys
which in turn unlock data on the server.

In graph form:

.. graphviz::

  digraph {
    ROOT [label="Key-Encrypting Key Bundle"];
    BOOKMARKS [label="Bookmarks Collection Key Bundle"];
    HISTORY [label="History Collection Key Bundle"];

    ROOT -> BOOKMARKS;
    ROOT -> HISTORY;

    BOOKMARKS -> "Bookmark A";
    BOOKMARKS -> "Bookmark B";

    HISTORY -> "History 1";
    HISTORY -> "History 2";
  }

This specification establishes no rules for which **crypto records** exist
or for how **Key-Encrypting Key Bundles** are managed. This is entirely up to
the client. In other words, key management is a convention between clients.
If you are interested in interoperating with Firefox Sync, see
:ref:`Mozilla's Sync Service<sync_mozilla>`.

This is the essence of the cryptographic model. More details are explained
below.

Representation of Key Pairs
---------------------------

While **Key Bundles** consist of two separate keys, they should be thought
of as a single immutable entity. To enforce this, a **Sync Key Bundle** is
represented as a single blob of data.

The blob consists of the 256 bits of the encryption key followed by the 256
bits of the HMAC key followed by optional metadata. The format of the metadata
is not currently defined. If no metadata is present, no extra information is
recorded and the **Key Bundle** is represented as a single 512 bit (64 byte)
blob.

In pseudo-code::

   key_bundle = encryption_key + hmac_key + metadata

When encoded in JSON, key bundles are Base64 encoded. Note that keys are not
stored in plaintext, so the Base64 encoding will apply to the ciphertext.
See below.

Encrypted Records
-----------------

Most encrypted records share a common payload format and method for encryption
and decryption.

The payload of an encrypted records effectively consists of the following
fields:

* **ciphertext**: The encrypted version of the underlying data.
* **IV**: Initialization vector used by AES encryption.
* **HMAC**: HMAC for the encrypted message.

Since these 3 items are all related and all are needed to decrypt and verify
individual messages, they are represented by a single entity - a buffer
containing all 3 fields concatenated together.

Each binary buffer holds the raw bytes constituting the HMAC signature,
followed by the raw bytes of the IV, followed by the raw bytes of the
ciphertext.

In pseudo-code::

   data = hmac + iv + ciphertext

The HMAC signature is always the length of the HMAC key. Since Sync uses 256-bit
HMAC keys, the HMAC signature is 256 bits, or 32 bytes.

The IV is fixed-width at 16 bytes.

The ciphertext is variable length.

We refer to this 3-tuple of encryption *matter* as **Encrypted Data**.

When represented in JSON, the raw bytes constituting the **Encrypted Data**
are Base64 encoded.

Encryption
^^^^^^^^^^

Encryption is the process of taking some piece of data, referred to as
**cleartext**, and converting it to **Encrypted Data**.

We start with a **Key Bundle** and cleartext.

In pseudo-code::

   # collection_name is the name of the collection this record will be inserted
   # into. The called function obtains the appropriate key bundle depending on
   # the destination collection of the record.
   bundle = getBundleForCollection(collection_name)

   # Just some aliasing for readability.
   encryption_key = bundle.encryption_key
   hmac_key = bundle.hmac_key

   iv = randomBytes(16)

   ciphertext = AES256Encrypt(encryption_key, iv, cleartext)

   # Now compute the HMAC. Be sure to include the IV in the computation.
   message = iv + ciphertext
   hmac = HMACSHA256(hmac_key, message)

   encrypted_data = hmac + message

   # When going to JSON, the binary payload buffer is Base64-encoded first.
   record.payload = Base64Encode(encrypted_data)

Decryption
^^^^^^^^^^

Decryption is the process of taking **Encryted Data** and turning it into
**cleartext**.

Decryption requires **Encrypted Data** and a **Key Bundle**.

In pseudo-code::

   bundle = getBundleForCollection(collection_name)
   encryption_key = bundle.encryption_key
   hmac_key = bundle.hmac_key

   # If grabbing the record from JSON, it will Base64 encoded.
   payload_b64 = record.payload
   encrypted_data = Base64Decode(payload_b64)

   # HMAC is first 32 bytes of payload.
   hmac_remote = encrypted_data[0:31]

   # IV is the 16 bytes after the HMAC
   iv = encrypted_data[32:47]

   # ciphertext is everything that's left.
   ciphertext = encrypted_data[48:]

   # The first step of decryption is verifying the HMAC. The HMAC is computed
   # over both the IV and the ciphertext.
   hmac_local = HMACSHA256(hmac_key, iv + ciphertext)

   if hmac_local != hmac_remote:
       throw new Error("HMAC verification failed!");

   cleartext = AESDecrypt(encryption_key, iv, ciphertext)

Global Metadata Record
======================

The **meta/global** record exists with the same semantics as version 5, the
only difference being that the **storageVersion** is **6** and the **engines**
key has been renamed to **repositories**.

**TODO carry version 5's documentation forward.**

Example::

   {
     "syncID": "7vO3Zcdu6V4I",
     "storageVersion": 6,
     "repositories":{
       "clients":   {"version":1,"syncID":"Re1DKzUQE2jt"},
       "bookmarks": {"version":2,"syncID":"ApPN6v8VY42s"},
       "forms":     {"version":1,"syncID":"lLnCTaQM3SPR"},
       "tabs":      {"version":1,"syncID":"G1nU87H-7jdl"},
       "history":   {"version":1,"syncID":"9Tvy_Vlb44b2"},
       "passwords": {"version":1,"syncID":"yfBi2v7PpFO2"},
       "prefs":     {"version":2,"syncID":"8eONx16GXAlp"}
     }
   }

crypto Collection
=================

There exists a special collection on the server named **crypto**. This
collection holds records that contain mappings of collections to **Collection
Key Bundles**.

Each record in the *crypto* collection has associated with it specific
semantics. This specification is intentionally vague as to what records and
semantics are defined, as it is up to clients to define those. In other words,
the set of records on the server and the specifics of which **Collection Key
Bundles** they contain and/or which **Key Encrypting Key Bundle** is used to
secure them is left to the purview of the client.

The rationale for this is that users may wish to manage their **Collection Key
Bundles** with different levels of access or security. For example, the record
containing all the keys may only be decrypted with a highly secure parent key,
while another record may contain keys for less-sensitive collections, which can
be unlocked using a key derived from a less secure method, such as PBKDF2.

Clients should support the ability to intelligently use different sets of
**Collection Key Bundles**, depending on what the user has provided them
access to. This means clients should not be eager to delete collections for
which it doesn't have the **Collection Key Bundle**, as the user may have
purposefully withheld access to that specific collection.

Record Format
-------------

The exact format of records in this collection has yet to be decided. We have
a few options.

Option 1
^^^^^^^^

The payload of every record is an object containing the following fields:

* **collections** - (required) A cleartext wrapping of collection names to
  **Encrypted Data**. The decrypted values are **Key Bundles** used to encrypt
  the collection to which it is tied.
* **encryptingKey** - (optional) An *encrypted** **Key Bundle** used to encrypt
  other encrypted data in this record.

For example::

   {
     "collections": {
        "bookmarks": "ENCRYPTED KEY 0",
        "history": "ENCRYPTED KEY 1"
     },
     "encryptingKey": "ENCRYPTED KEY-ENCRYPTING KEY"
   }

The client would -- if not delivered out-of-band -- decrypt the encrypting key.
This would require its parent key and the contents of this record.

The client would then take the decrypted key-encrypting key and decrypt the
individual **Collection Key Bundles**.

Pros:

* Simple

Cons:

* Server data reveals which encrypting keys can be used to unlock which
  collections.

Option 2
^^^^^^^^

This is similar to Option 1 except that the mapping info is itself encrypted.

For example::

   {
     "data": "ENCRYPTED DATA",
     "encryptingKey": "ENCRYPTED KEY-ENCRYPTING KEY"
   }

The decrypted key encrypting key would first decrypt the *data* field. This
would expose the mapping of collection names to *encrypted* **Key Bundles**,
just as in Option 1. From there, the same key-encrypting key would
decrypt each individual **Key Bundle**.

Yes, the **Key Bundles** are encrypted with the same key twice. We do not want
the **Key Bundles** unencrypted after the first unwrapping because we want
clients to be designed such that they never have to touch unencrypted key
matter. In the case of Firefox, this means Sync can operate in FIPS mode since
NSS will be the only entity handling the unencrypted keys.

Pros:

* Server data does not reveal which keys can unlock which collections

Cons:

* More complicated than version 1
* Double encryption involves extra work.

No encryptingKey Variation
^^^^^^^^^^^^^^^^^^^^^^^^^^

There is a variation of the above options where the *encrypted* key encrypting
key is not stored in the record. Instead, it is stored in another record on
the server or not stored on the server at all. These variations differ only in
the specifics of the record payload.

Changes Since Version 5
=======================

Sync Keys Consolidated
----------------------

The Sync Key has traditionally been 128 bits (often encoded as 26 "friendly"
Base32 characters). The historical reason for it being 128 bits is that in
early versions of Sync (before J-PAKE), people would need to manually enter
the Sync Key to pair other devices. Even with J-PAKE, people may need to
manually enter the Sync Key (known as the *Recovery Key* in UI parlance) into
their client. From the 128-bit Sync Key, two 256-bit keys were derived via HKDF.

With the intent to use BrowserID's key wrapping facility, we feel Sync no
longer has the requirement that the Sync Key be manageable to enter from
UI. This is because your Sync Key will be accessible merely by logging into
BrowserID (your BrowserID credentials will unlock a BrowserID user key and
that user key can unwrap an *encrypted* Sync Key stored on the server).

(We expect that users not using BrowserID will use some other mechanism for
key exchange other than keyboard entry.)

Therefore, in version 6, the Sync Key will consist of a pair of 256-bit keys.
Each key will be generated from a cryptographically secure random number
generator and will not be derived from any other source. This effectively
replaces the single 128-bit random key and two 256-bit HKDF-derived keys with
two completely random 256-bit keys.

Sync Key Stored on Server
=========================

Version 6 supports storing the **encrypted** Sync Key on the Storage Server.

Key Pair Encoding
-----------------

In version 5, key pairs (the two 256-bit keys used for symmetric encryption and
HMAC verification) were represented in payloads as arrays consisting of two
strings, each representing the Base64 encoded version of the key.

In version 6, key pairs are transmitted as a a single string or byte array.
The two keys are merely concatenated together to form one 512-bit data chunk.
Version 6 also supports additional metadata after the keys. However, the format
of this metadata is not yet defined.

IV Included in HMAC Hash
------------------------

In version 6, the IV is included in the HMAC hash. In previous versions, the
IV was not included. This change adds more theoretical security to the
verification process.

HMAC Performed Over Raw Ciphertext
----------------------------------

In version 6, the HMAC is performed over the raw ciphertext bytes. In version
5, HMAC was performed over the Base64 encoding of the ciphertext.

Representation of Crypto Fields in Records
------------------------------------------

In version 6, the representation of cryptographic fields has been hidden from
the record payload.

In version 5, the payload of encrypted records was the Base64 encoding of
the JSON encoding of an object with the fields *ciphertext*, *hmac*, and *IV*.

In version 6, we embed all 3 elements in one opaque field. While the client
will need to know how to extract the individual cryptographic components, the
transport layer happily deals with a single string of bytes. In the case of
JSON encoding, the payload is now the Base64 representation of the single
string, not a JSON string.

Requiring Storing Separate Key Pairs for Collections
----------------------------------------------------

Version 6 requires that separate **Key Bundles** be used for each collection.

The previous version had a *default* **Key Bundle** that could be used to
decrypt multiple collections. Clients would look for a collection-specific key
in the crypto/keys record then fall back to the *default*. In practice, clients
(notably Firefox), did not generate multiple keys by default.

Version 6 is dropping support for the *default* key and requiring that each
collection use a separate key.

This change is being made in an effort to be forward compatible with future
data recovery and sharing scenarios. The requirement of separate keys per
collections effectively requires an extra link in the crypto chain where
extra functionality can be inserted for one collection without impacting
other collections.

Metaglobal Record Format Change
-------------------------------

The **engines** key in the metaglobal record has been renamed to
**repositories**. Semantics are preserved.
