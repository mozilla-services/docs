.. _sync_storageformat6:

========================
Global Storage Version 6
========================

This document describes version 6 of Sync's global storage format. This
describes not only the technical details of the storage format, but also some
semantics for how clients supporting version 6 should interact with the Sync
server.

PROPOSAL
========

**This document is an unofficial proposal. It can and will change.**

Cryptographic Model
===================

The cryptographic model frequently relies on pairs of 256 bit keys. One key is
used for AES symmetric encryption; the other for HMAC verification. We refer to
a single key pair as a **Sync Key Pair**.

There exists a special **Sync Key Pair** called the **Sync Root Key**. The
**Sync Root Key** is effectively a master key used to encrypt and decrypt
other keys.

Tied to each collection on the server is a specific **Sync Key Pair**. These
keys are completely different from the **Sync Root Key**. Together, the
**Sync Key Pairs** tied to collections comprise the **Sync Key Bundle**.
The **Sync Key Bundle** is just a container that holds **Sync Key Pair**
instances and maps them to collections.

The **Sync Root Key** encrypts the **Sync Key Bundle** (and the keys inside).
The encrypted **Sync Key Bundle** is stored on the server.

Data is encrypted on the client using the **Sync Key Pair** appropriate for
the collection it will be uploaded to.

The **Sync Root Key** can itself be encrypted and stored on the server. The
mechanism for doing this is not explicitly defined by this specification.

Representation of Key Pairs
---------------------------

While **Sync Key Pairs** consist of two separate keys, they should be thought
of as a single immutable entity. To enforce this, a **Sync Key Pair** is
represented as a single blob of data, not 2. The blob simply consists of the
512 total bits (64 bytes) comprising the 2 keys. Inside, the HMAC key is
appended to the encryption key.

In pseudo-code::

   key_pair = encryption_key + hmac_key

When encoded in JSON, these 512 bit buffers are Base64 encoded.

Encrypted Records
-----------------

All encrypted records share a common payload format and method for encryption
and decryption.

The payload of an encrypted records effectively consists of the following
fields:

* **ciphertext**: The encrypted version of the underlying data.
* **IV**: Initialization vector used by AES encryption.
* **HMAC**: HMAC for the encrypted message.

Since these 3 items are all related and all are needed to decrypt and verify
individual records, they are represented by a single entity, a buffer
containing all 3 fields concatenated together.

Each binary buffer holds the raw bytes constituting the HMAC signature,
followed by the raw bytes of the IV, followed by the raw bytes of the
ciphertext.

In pseudo-code::

   data = hmac + iv + ciphertext

The HMAC signature is always the length of the HMAC key. Since Sync uses 256
bit HMAC keys, the HMAC signature is 256 bits, or 32 bytes.

The IV is fixed-width at 16 bytes.

The ciphertext is variable length.

Encryption
^^^^^^^^^^

Encryption is the process of taking some piece of data, referred to as
**cleartext** and converting it to a payload suitable for a record.

We start with a **Sync Key Pair** (which consists of 2 separate keys) and
cleartext.

In pseudo-code::

   # collection_name is the name of the collection this record will be inserted
   # into. The called function obtains the appropriate key pair depending on
   # the collection the record is destined for.
   key_pair = getKeyPairForCollection(collection_name)

   # Just some aliasing for readability.
   encryption_key = key_pair.encryption_key
   hmac_key = key_pair.hmac_key

   iv = randomBytes(16)

   ciphertext = AES256(encryption_key, iv, cleartext)

   message = iv + ciphertext

   hmac = HMACSHA256(hmac_key, message)

   payload = hmac + message

   # When going to JSON, the binary payload buffer is Base64 encoded first.
   payload_b64 = Base64Encode(payload)

   record.payload = payload_b64

Decryption
^^^^^^^^^^

Decryption is the process of taking an encrypted payload and verifying and
decrypting it with a **Sync Key Pair**.

In pesudo-code::

   # If grabbing the record from JSON, it will Base64 encoded.
   payload_b64 = record.payload
   payload = Base64Decode(payload_b64)

   # HMAC is first 32 bytes of payload.
   hmac_record = payload[0:31]

   TODO

Metaglobal Record
=================

The **meta/global** record exists with the same semantics as version 5.

**TODO carry version 5's documentation forward.**

crypto/master Record
====================

Version 6 introduces the **crypto/root** record. This record holds an
**encrypted** **Sync Root Key**.

The payload is the record is the Base64 representation of the ciphertext
of the **Sync Root Key**.

Encryption, in pseudo-code::

    // Obtain the 512 bits of Sync Key data.
    syncKey = getSyncKey()

    // Perform asymmetric encryption, sign the ciphertext. Returns a string
    // with ciphertext, HMAC, and IV embedded in it.
    wrapped = encryptAndSign(syncKey, keypair);

    record.payload = Base64(wrapped);

crypto/keys Record
==================

The **crypto/keys** records exists with **nearly** the same semantics as
version 5.

In version 6, the value for key pairs has been changed to a single string.
That single string represents both 256 bit keys.

Version 6 also recommends that clients take advantage of the separate key pairs
per collection. Previously, clients typically only stored the default key pair.

**TODO copy content from version 5 documentation.**

Changes Since Version 5
=======================

Sync Keys Consolidated
----------------------

The Sync Key has traditionally been 128 bits (often encoded as 26 "friendly"
Base32 characters). The historical reason for it being 128 bits is that in
early versions of Sync (before J-PAKE), people would need to manually enter
the Sync Key to pair other devices. Even with J-PAKE, people may need to
manually enter the Sync Key (known as the *Recovery Key* in UI parlance) into
their client. From the 128 bit Sync Key, 2 256 bit keys were derived via HKDF.

With BrowserID, the Sync Key will be encrypted by a more easily recoverable
BrowserID key and the need for manually entering the Sync Key will be lower.

In version 6, the Sync Key will consist of a pair of 256 bit keys. Each key
will be generated randomly and will not be derived from any other source.

This means that the Sync Key effectively increases in size from 128 bits to
512 bits. This means that it will now take 104 Base32 characters to represent
the Sync Key. This is not something mere mortals will want to do by hand.

Sync Key Stored on Server
=========================

Version 6 supports storing the **encrypted** Sync Key on the Storage Server in
the *crypto/master* record. This record is encrypted using a symmetric key
that is never transmitted to the Sync Server and is only known to the client.

Key Pair Encoding
-----------------

In version 5, key pairs (the 2 256 bit keys used for symmetric encryption and
HMAC verification) were represented in payloads as arrays consisting of two
strings, each representing the Base64 encoded version of the key.

In version 6, key pairs are transmitted as a a single string or byte array.
The 2 keys are merely concatenated together to form 1 512 bit data chunk.
The data is Base64 encoded, like before.

IV Included in HMAC Hash
------------------------

In version 6, the IV is included in the HMAC hash. In previous versions, the
IV was not included. This change theoretically adds more security to the
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
string.

Recommendation of Storing Separate Key Pairs for Collections
------------------------------------------------------------

Version 6 recommends that clients take advantage of the ability of the
**crypto/keys** collection to hold multiple key pairs, one for each collection.
Previously, clients needed to support this functionality. In practice, clients
typically didn't generate additional key pairs and used the default key pair
for all collections.

This recommendation is being made so clients may better support future data
recovery and sharing scenarios. For example, if a user wishes to "share" her
data with someone else (perhaps for backup purposes in case the Sync Key is
lost), she can choose to reveal keys to specific collections without
compromising access to all collections.
