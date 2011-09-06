=========
User Flow
=========

Desired User Flow
=================

There are two possible scenarios when pairing two devices. In the simplest
case, one of the devices is already connected to Sync. This is the only
scenario considered in **v1/v2**. In other other scenario, none of the devices
are connected to Sync and the user has to connect to or create a Sync account
on one of them after the pairing. This scenario is new in **v3**.

For the sake of this document, "Mobile" refers to the a mobile device
or a desktop computer and "Desktop" refers to a desktop computer.

1. User chooses "Pair Device" on Mobile.
2. Mobile displays a setup key that contains both the initial secret
   and a channel ID.
3. On Desktop, user chooses "Pair Device" according to the
   instructions displayed on Device.
4. Mobile and Desktop exchange messages to build the secure channel
5. Once the channel has been established and Mobile and Desktop are
   "paired", the user creates a Sync account on Desktop and Desktop
   uploads its data to the server during the first sync. This step is
   not present in v1/v2 of this flow. It can be omitted if the user
   already has an account, of course.
6. Desktop transmits the Sync account credentials (username, password,
   Sync Key) to Mobiel via the channel.
7. Mobile completes setup and starts syncing.

Overview
========

- Mobile and Desktop complete the two roundtrips of J-PAKE messages to agree 
  upon a strong secret K
- A 256 bit key is derived from K using HMAC-SHA256 using a fixed extraction 
  key.
- The encryption and HMAC keys are derived from that 256 bit key using 
  HMAC-SHA256.
- To establish the pairing, Mobile encrypts the known message
  "0123456789ABCDEF" with the AES key and uploads it. Desktop verifies that it
  has the same key by encrypting the known message with the key Desktop
  derived.
- To exchange credentials after a successful pairing and possibly account
  creation on Desktop,

  - Desktop encrypts the credentials with the encryption key and uploads the 
    encrypted credentials in turn, adding a HMAC-SHA256 hash of the ciphertext
    (using the HMAC key).
  - Mobile verifies the ciphertext against the HMAC-SHA256 hash.  If
    successful, Mobile decrypts ciphertext and applies credentials
  - Mobile beings sync


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

     At this point Desktop knows whether the PIN was entered correctly.
     If it wasn't, Desktop deletes the session. If it was, the account
     setup can proceed. If Desktop doesn't have an account set up yet,
     it will keep the channel open and let the user connect to or
     create an account.

                                     |              encrypt credentials
                                     |<------------- upload credentials
    retrieve credentials <-----------|
    verify HMAC                      |
    decrypt credentials              |
    delete session ----------------->|
    start syncing                    |


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
    C:    'version': 3,   // new in v3
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

  **New in v3:** Prior to v3, clients would only allow a 10 second timeout for
  messages after the first. This means that if Desktop has no credentials yet,
  a Mobile client that implements v2 or lower will not wait for the account
  setup to finish. Desktop should therefore detect Mobile's API version at this
  point and abort the pairing right away if there are no credentials present on
  Desktop.

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
    C:    'version': 3,   // new in v3
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
    C:    'version': 3,   // new in v3
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
    C:    'version': 3,   // new in v3
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
        C:    'version': 3,   // new in v3
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

   Desktop verifies it against its own version. If the values don't match,
   the pairing is aborted and the session should be deleted.

   Once credentials are available, and if the channel is still available,
   Desktop encrypts the credentials and uploads them.

   **New in v2:** The ``If-Match`` header may be set so that we only upload 
   this message if the other side's previous message is still in the channel. 
   This is to prevent double PUTs during retries. If a 412 is received then 
   it means that our first PUT was actually correctly received by the server 
   and that the other side has already uploaded it's next message. So just 
   consider the 412 to be a 200.

   **New in v3:** Desktop must include the If-Match header to ensure the
   session hasn't been deleted yet (e.g. due to a timeout) or tampered with
   in the mean time.

   ::

        C: PUT /a7id HTTP/1.1
        C: If-Match: "etag-of-receiver3-message"
        C: 
        C: {
        C:    'type': 'sender3',
        C:    'version': 3,   // new in v3
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


9. Mobile polls for the encrypted credentials once per second for at least
   300 seconds to allow for the account process (the increased timeout is
   **new in v3**)::

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

11. Mobile starts syncing.
