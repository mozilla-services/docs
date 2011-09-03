=========
User Flow
=========

Desired User Flow
=================

1. User chooses "quick setup" on new device
2. Device displays a setup key that contains both the initial secret and a channel ID
3. On a device that is authenticated, user chooses "add another device" and is prompted for that key
4. The two devices exchange messages to build the secure tunnel
5. The already-authenticated device passes all credentials (username/password/sync key) to the new device
6. New device completes setup and starts syncing 

Overview
========

- Mobile and Desktop complete the two roundtrips of J-PAKE messages to agree 
  upon a strong secret K
- A 256 bit key is derived from K using HMAC-SHA256 using a fixed extraction 
  key.
- The encryption and HMAC keys are derived from that 256 bit key using 
  HMAC-SHA256.
- In third round trip:

  - Mobile encrypts the known message "0123456789ABCDEF" with the AES key and 
    uploads it.
  - Desktop verifies that against the known message encrypted with its own 
    key, encrypts the credentials with the encryption key and uploads the 
    encrypted credentials in turn, adding a HMAC-SHA256 hash of the ciphertext
    (using the HMAC key).
  - Mobile verifies whether Desktop had the right key by checking the ciphertext 
    against the HMAC-SHA256 hash.
  - If that verification is successful, Mobile decrypts ciphertext and applies 
    credentials


::

    Mobile                        Server                        Desktop
    ===================================================================
                                     |
    retrieve channel <---------------|
    generate random secret           |
    show PIN = secret + channel      |                 ask user for PIN
    upload Mobile's message 1 ------>|
                                     |----> retrieve Mobile's message 1
                                     |<----- upload Desktop's message 1
    retrieve Desktop's message 1 <---|
    upload Mobile's message 2 ------>|
                                     |----> retrieve Mobile's message 2
                                     |                      compute key
                                     |<----- upload Desktop's message 2
    retrieve Desktop's message 2 <---|
    compute key                      |
    encrypt known value ------------>|
                                     |-------> retrieve encrypted value
                                     | verify against local known value
                                     |              encrypt credentials
                                     |<------------- upload credentials
    retrieve credentials <-----------|
    verify HMAC                      |
    decrypt credentials              |


Detailed Flow
=============

1. Mobile asks server for new channel ID (4 characters a-z0-9)

   ::
    
       C: GET /new_channel HTTP/1.1
       S: "a7id"


2. Mobile generates PIN from random weak secret (4 characters a-z0-9) 
   and the channel ID, computes and uploads J-PAKE msg 1.

   **New in v2:** To prevent double uploads in case of retries, the 
   ``If-None-Match: *`` header may be specified. This ensures that the message
   is only uploaded if the channel is empty. If it is not then the request 
   will fail with a 412 Precondition Failed which should be considered the 
   same as 200 OK. The 412 will also contain the Etag of the data was the 
   client just uploaded.

   ::

    C: PUT /a7id HTTP/1.1
    C: If-None-Match: *
    C: 
    C: {
    C:    'type': 'receiver1',
    C:    'payload': {
    C:       'gx1': '45...9b',
    C:       'zkp_x1': {
    C:          'b': '09e22607ead737150b1a6e528d0c589cb6faa54a',
    C:          'gr': '58...7a'
    C:          'id': 'receiver',
    C:       }
    C:       'gx2': 'be...93',
    C:       'zkp_x2': {
    C:          'b': '222069aabbc777dc988abcc56547cd944f056b4c',
    C:          'gr': '5c...23'
    C:          'id': 'receiver',
    C:       }
    C:    }
    C: }

   Success response::

    S: HTTP/1.1 200 OK
    S: ETag: "etag-of-receiver1-message"

   **New in v2:** Response that will be returned on retries if the Desktop
   already replaced the message::

    S: HTTP/1.1 412 Precondition Failed
    S: ETag: "etag-of-receiver1-message"


3. Desktop asks user for the PIN, extracts channel ID and weak secret, fetches 
   Mobile's msg 1::

    C: GET /a7id HTTP/1.1

   Success response::

    S: HTTP/1.1 200 OK
    S: ETag: "etag-of-receiver1-message"

4. Desktop computes and uploads msg 1.

   **New in v2:** The ``If-Match`` header may be set so that we only upload this
   message if the other side's previous message is still in the channel. This 
   is to prevent double PUTs during retries. If a 412 is received then it 
   means that our first PUT was actually correctly received by the server and 
   that the other side has already uploaded it's next message. 
   So just consider the 412 to be a 200.

   ::

    C: PUT /a7id HTTP/1.1
    C: If-Match: "etag-of-receiver1-message"
    C: 
    C: {
    C:    'type': 'sender1',
    C:    'payload': {
    C:       'gx1': '45...9b',
    C:       'zkp_x1': {
    C:          'b': '09e22607ead737150b1a6e528d0c589cb6faa54a',
    C:          'gr': '58...7a'
    C:          'id': 'sender',
    C:       }
    C:       'gx2': 'be...93',
    C:       'zkp_x2': {
    C:          'b': '222069aabbc777dc988abcc56547cd944f056b4c',
    C:          'gr': '5c...23'
    C:          'id': 'sender',
    C:       }
    C:    }
    C: }

   Success response::

    S: HTTP/1.1 200 OK
    S: Etag: "etag-of-sender1-message"

   **New in v2:** Response that will be returned on retries if Mobile
   already replaced the message::

    S: HTTP/1.1 412 Precondition Failed
    S: Etag: "etag-of-sender1-message"


5. Mobile polls for Desktop's msg 1 once per second for at least 300 seconds::

    C: GET /a7id HTTP/1.1
    C: If-None-Match: "etag-of-receiver1-message"

    S: HTTP/1.1 304 Not Modified

   Mobile tries again after 1s::

    C: GET /a7id HTTP/1.1

    S: HTTP/1.1 200 OK
    S: Etag: "etag-of-sender1-message"

   Mobile computes and uploads msg 2.

   **New in v2:** The ``If-Match`` header may be set so that we only upload this
   message if the other side's previous message is still in the channel. This 
   is to prevent double PUTs during retries. If a 412 is received then it means 
   that our first PUT was actually correctly received by the server and that 
   the other side has already uploaded it's next message. So just consider the 
   412 to be a 200.::

    C: PUT /a7id HTTP/1.1
    C: If-Match: "etag-of-sender1-message"
    C: 
    C: {
    C:    'type': 'receiver2',
    C:    'payload': {
    C:       'A': '87...82',
    C:       'zkp_A': {
    C:          'b': '6f...08',
    C:          'id': 'receiver',
    C:          'gr': 'f8...49'
    C:       }
    C:    }
    C: }

    S: HTTP/1.1 200 OK
    S: ETag: "etag-of-receiver2-message"

   **New in v2:** Response that will be returned on retries if Desktop
   already replaced the message::

    S: HTTP/1.1 412 Precondition Failed
    S: ETag: "etag-of-receiver2-message"

6. Desktop polls for Mobile's msg 2 once per second for at least 10 seconds::

    C: GET /a7id HTTP/1.1
    C: If-None-Match: "etag-of-sender1-message"

    S: HTTP/1.1 304 Not Modified

   and eventually retrieves it::

    S: HTTP/1.1 200 OK
    S: Etag: "etag-of-receiver2-message"

   Desktop computes key, computes and uploads msg 2.

   **New in v2:** The ``If-Match`` header may be set so that we only upload this
   message if the other side's previous message is still in the channel. This 
   is to prevent double PUTs during retries. If a 412 is received then it 
   means that our first PUT was actually correctly received by the server and 
   that the other side has already uploaded it's next message. So just 
   consider the 412 to be a 200.

   ::

    C: PUT /a7id HTTP/1.1
    C: If-Match: "etag-of-receiver2-message"
    C: 
    C: {
    C:    'type': 'sender2',
    C:    'payload': {
    C:       'A': '87...82',
    C:       'zkp_A': {
    C:          'b': '6f...08',
    C:          'id': 'sender',
    C:          'gr': 'f8...49'
    C:       }
    C:    }
    C: }

    S: HTTP/1.1 200 OK
    S: ETag: "etag-of-sender2-message"

   **New in v2:** Response that will be returned on retries if Mobile
   already replaced the message::

    S: HTTP/1.1 412 Precondition Failed
    S: ETag: "etag-of-sender2-message"


7. Mobile polls for Desktop's msg 2 once per second for at least 10
   seconds and eventually retrieves it::

    C: GET /a7id HTTP/1.1
    C: If-No-Match: "etag-of-receiver2-message"

    S: HTTP/1.1 200 OK
    S: Etag: "etag-of-sender2-message"
    { 'type': 'sender2', ... }

    S: HTTP/1.1 304 Not Modified

   Mobile computes key, uploads encrypted known message "0123456789ABCDEF" to 
   prove its knowledge (msg 3).

   **New in v2:** The ``If-Match`` header may be set so that we only upload 
   this message if the other side's previous message is still in the channel. 
   This is to prevent double PUTs during retries. If a 412 is received then it 
   means that our first PUT was actually correctly received by the server and 
   that the other side has already uploaded it's next message. 
   So just consider the 412 to be a 200.

   ::

        C: PUT /a7id HTTP/1.1
        C: If-Match: "etag-of-sender2-message"
        C: 
        C: {
        C:    'type': 'receiver3',
        C:    'payload': {
        C:       'ciphertext': "base64encoded=",
        C:       'IV': "base64encoded=",
        C:    }
        C: }

        S: HTTP/1.1 200 OK
        S: Etag: "etag-of-receiver3-message"

   **New in v2:** Response that will be returned on retries if Desktop
   already replaced the message::

        S: HTTP/1.1 412 Precondition failed
        S: Etag: "etag-of-receiver3-message"


8. Desktop retrieves Mobile's msg 3 to confirm the key. It polls once
   per second for at least 10 seconds::

    C: GET /a7id HTTP/1.1
    C: If-No-Match: "etag-of-sender2-message"

    S: HTTP/1.1 200 OK
    C: ETag: "etag-of-receiver3-message"
    ...

   Desktop verifies it against its own version.  If the encrypted values
   match, it encrypts and uploads Sync credentials.

   **New in v2:** The ``If-Match`` header may be set so that we only upload 
   this message if the other side's previous message is still in the channel. 
   This is to prevent double PUTs during retries. If a 412 is received then 
   it means that our first PUT was actually correctly received by the server 
   and that the other side has already uploaded it's next message. So just 
   consider the 412 to be a 200.

   ::

        C: PUT /a7id HTTP/1.1
        C: If-Match: "etag-of-receiver3-message"
        C: 
        C: {
        C:    'type': 'sender3',
        C:    'payload': {
        C:       'ciphertext': "base64encoded=",
        C:       'IV': "base64encoded=",
        C:       'hmac': "base64encoded=",
        C:    }
        C: }


        S: HTTP/1.1 200 OK
        S: Etag: "etag-of-sender3-message"

   **New in v2:** Response that will be returned on retries if Mobile
   already replaced the message::

        S: HTTP/1.1 412 Precondition failed
        S: Etag: "etag-of-sender3-message"


   If the hash does not match, the Desktop deletes the session::

        C: DELETE /a7id HTTP/1.1

        S: HTTP/1.1 200 OK
        ...

   This means that Mobile will receive a 404 when it tries to retrieve 
   the encrypted credentials.


9. Mobile polls for the encrypted credentials once per second for at
   least 10 seconds::

    C: GET /a7id HTTP/1.1
    C: If-None-Match: "etag-of-receiver3-message"

    S: HTTP/1.1 200 OK
    ... 

   Decrypts Sync credentials and verifies HMAC.


10. Mobile deletes the session [OPTIONAL]

    ::

     C: DELETE /a7id HTTP/1.1

     S: HTTP/1.1 200 OK
     ... 

