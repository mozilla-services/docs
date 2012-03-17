.. _sync_cryptography:

=================
Sync Cryptography
=================

This document serves as an overview of Sync's cryptographic model. The model
documented here applies to :ref:`version 5 <sync_storageformat5>` of Sync's
global storage format.

Overview
========

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
===========

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

HMAC Hasing
    A technique used to verify that messages (**Ciphertexts**) haven't been
    tampered with. A **HMAC Key** is applied over a **Ciphertext** to produce
    a **HMAC Value.**

The Sync Key
============

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
===============

The *Sync Key Bundle* is a *key bundle* derived from the *Sync Key* via
SHA-256 HMAC-based HKDF (`RFC 5869 <http://tools.ietf.org/html/rfc5869>`_).

Remember that a *key bundle* consists of a 256 bit symmetric *encryption key*
and a *HMAC key*.

In pesudo-code::

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
=================

Individual records are encrypted using the AES algorithm + HMAC "signing" using
keys from a *key bundle*.

You take your cleartext input (which is typically a JSON string representing an
object) and feed it into AES. You Base64 encode the raw byte output of that and
feed that into HMAC SHA-256.

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
=================

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
=====================

When a new Sync account is initially configured or when an existing Sync
account is reset, we perform an initial bootstrap of the cryptographic
components.

1. The *Sync Key* is generated.
2. The *Sync key bundle* is derived from the *Sync Key*.
3. New *key bundles* are created.
4. The new *key bundles* are assembled into a *bulk key bundle*/record and
   uploaded to the server after being encrypted by the *Sync key bundle*.

At this point, the client is bootstrapped from a cryptography perspective.

