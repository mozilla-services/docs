.. _sync_cryptokeys:

==================
crypto/keys Record
==================

In storage Version 5, the public/private key layer has been dropped. All bulk keys are now stored in this one WBO. Encryption and HMAC keys are separate keys and kept in key pairs.


Encrypting and decrypting
-------------------------

The ```crypto/keys``` WBO is encrypted and verified just like any other WBO, except a different key bundle is used. The key bundle for the '''keys''' WBO is derived from the Sync Key using an HKDF with HMAC-SHA256 as the HMAC function (see `RFC 5869 <http://tools.ietf.org/html/rfc5869>`_):

Pseudo-code::

  HMAC_INPUT = "Sync-AES_256_CBC-HMAC256"
  encryption_key = HMAC-SHA256(sync_key, "" + HMAC_INPUT + username + "\x01")
  hmac_key = HMAC-SHA256(sync_key, encryption_key + HMAC_INPUT + username + "\x02")

Here ``sync_key`` is the 16 byte representation of the Sync Key. To translate between the byte and user-readable translation, base32 is used, although with a slightly different alphabet than what `RFC 4648 <http://tools.ietf.org/html/rfc4648>`_ uses. For readability reasons, 'l' has been replaced with '8' and 'o' with '9'::

  sync_key = decodeBase32(sync_key_ui.replace('8', 'l').replace('9', 'o'))
  sync_key_ui = encodeBase32(sync_key).replace('l', '8').replace('o', '8)


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
