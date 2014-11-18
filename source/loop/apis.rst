====================
Loop Server API v1.0
====================

This document is based on the current status of the server. All the examples
had been done with real calls. It doesn't reflect any future implementation and
tries to stick with the currently deployed version.

This document describes the :ref:`HTTP APIs <http-apis>` and the
:ref:`Websockets APIs <websockets-apis>`.

.. contents::

.. _http-apis:

HTTP APIs
=========

Overview
--------

.. note::

    Unless stated otherwise, all APIs are using application/json for the requests
    and responses content types. Parameters for the GET requests are form
    encoded (?key=value&key2=value2)

To ease testing, you can use `httpie <https://github.com/jkbr/httpie>`_ in
order to make requests. Examples of use with httpie are provided when possible.
In order to authenticate with hawk, you'll need to install the `requests-hawk
module <https://github.com/mozilla-services/requests-hawk>`_

Versioning
----------

The current API is versioned, using only a major version. All the endpoints for
version 1 are prefixed by `/v1/`. In case you don't specify the prefix, your
requests will be redirected automatically with an http `307` status.

.. _hawk-authentication:

Authentication
--------------

To deal with authentication, the Loop server uses `Hawk
<https://github.com/hueniverse/hawk>`_ sessions. When you
register, you can do so with different authentications schemes, but you are
always given an hawk session back, that you should use when requesting the
endpoints which need authentication.

When authenticating using the `/register` endpoint, you will be given an hawk
session token in the `Hawk-Session-Token` header. You will need to derive it,
as explained at :ref:`derive_hawk`.

.. _derive_hawk:

Derive hawk credentials from the hawk session token
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In order to get the hawk credentials to use on the client you will need to:

1. Do an `HKDF derivation <http://en.wikipedia.org/wiki/HKDF>`_ on the given
   session token. You'll need to use the following parameters::

    key_material = HKDF(hawk_session, "", 'identity.mozilla.com/picl/v1/sessionToken', 32*2)

2. The key material you'll get out of the HKDF need to be separated into two
   parts, the first 32 hex caracters are the hawk id, and the next 32 ones are the hawk
   key.

   Credentials::

        credentials = {
            'id': keyMaterial[0:32]
            'key': keyMaterial[32:64]
            'algorithm': 'sha256'
        }

If you are writting a client, you might find these resources useful:

- With javascript:
  https://mxr.mozilla.org/mozilla-central/source/services/fxaccounts/FxAccountsClient.jsm#309 &
  https://github.com/mozilla/gecko-projects/blob/elm/browser/components/loop/content/shared/libs/token.js#L55-L77
- With python:
  https://github.com/mozilla-services/loop-server/blob/master/loadtests/loadtest.py#L99-L122

Configuration
-------------

GET /
~~~~~

    Displays version information, for instance::

       http GET localhost:5000/v1 --verbose

    .. code-block:: http

        GET /v1/ HTTP/1.1
        Accept: */*
        Accept-Encoding: gzip, deflate
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0


        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 247
        Content-Type: application/json; charset=utf-8
        Date: Wed, 16 Jul 2014 12:57:13 GMT
        ETag: W/"f7-762153207"
        Timestamp: 1405515433

        {
            "description": "The Mozilla Loop (WebRTC App) server",
            "endpoint": "http://localhost:5000",
            "fakeTokBox": false,
            "homepage": "https://github.com/mozilla-services/loop-server/",
            "name": "mozilla-loop-server",
            "version": "0.9.0"
        }

GET /push-server-config
~~~~~~~~~~~~~~~~~~~~~~~

    Retrieves the configuration of the push server. Specifically, returns the
    websocket endpoint that should be used to reach simple push.

    The response should contain a **pushServerURI** parameter with this
    information.

    .. code-block:: http

        http localhost:5000/push-server-config

        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 57
        Content-Type: application/json; charset=utf-8
        Date: Tue, 19 Aug 2014 14:26:42 GMT
        ETag: W/"39-351294056"
        Timestamp: 1408458402

        {
            "pushServerURI": "wss://push.services.mozilla.com/"
        }

    Server should acknowledge your request and answer with a status code of
    **200 OK**.


Healthcheck
-----------

GET /__healthcheck__
~~~~~~~~~~~~~~~~~~~~

   - Returns 200 in case of success
   - Returns 503 with the backend error message in case backends are broken

    .. code-block:: http

        http localhost:5000/__heartbeat__

        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 32
        Content-Type: application/json; charset=utf-8
        Date: Fri, 07 Nov 2014 13:02:45 GMT
        ETag: W/"20-e938360a"
        Timestamp: 1415365365

        {
            "provider": true,
            "storage": true
        }


Registration
------------

POST /registration
~~~~~~~~~~~~~~~~~~

    Associates a Simple Push Endpoint (URL) with a user.
    Always return an hawk session token in the `Hawk-Session-Token` header.

    **May require authentication**

    You don't *need* to be authenticated to register. In case you don't
    register with a Firefox Accounts assertion or a valid hawk session, you'll
    be given an hawk session token and be connected as an anonymous user.

    This hawk session token should be derived by the client and used for
    subsequent requests.

    You can currently authenticate by sending a valid Firefox Accounts
    assertion or a valid Hawk session.

    Body parameters:

    - **simplePushURL**, the simple push endpoint url as defined in
      https://wiki.mozilla.org/WebAPI/SimplePush#Definitions

    Example (when not authenticated)::

        http POST localhost:5000/v1/registration --verbose \
        simplePushURL=https://push.services.mozilla.com/update/MGlYke2SrEmYE8ceyu

    .. code-block:: http

        POST /v1/registration HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Content-Length: 35
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "simplePushURL": "https://test"
        }

        HTTP/1.1 200 OK
        Access-Control-Expose-Headers: Hawk-Session-Token
        Connection: keep-alive
        Content-Length: 4
        Content-Type: application/json; charset=utf-8
        Date: Wed, 16 Jul 2014 12:58:56 GMT
        Hawk-Session-Token: c7ee533a75a4f3b8a2a44b0b417eec15295ad43ff2b402776078ec87abb31cd9
        Timestamp: 1405515536

        "ok"

    Server should acknowledge your request and answer with a status code of
    **200 OK**.

    Potential HTTP error responses include:

    - **400 Bad Request:**  You forgot to pass the simple_push_url, or it's
      not a valid URL.
    - **401 Unauthorized:** The credentials you passed aren't valid.


DELETE /registration
~~~~~~~~~~~~~~~~~~~~

    **Requires authentication**

    Unregister the given session's SimplePushURLs. The server will not
    be able to notify the client for this session.

    Example::

      http DELETE localhost:5000/v1/registration --verbose \
      --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        DELETE /v1/registration HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: <Stripped>
        Host: localhost:5000
        Content: 0
        User-Agent: HTTPie/0.8.0


        HTTP/1.1 204 No Content
        Connection: keep-alive
        Date: Wed, 16 Jul 2014 13:03:39 GMT
        Server-Authorization: <stripped>


    Server should acknowledge your request and answer with a status code of
    **204 No Content**.

    Potential HTTP error responses include:

    - **400 Bad Request:**  You forgot to pass the simplePushURL, or it's
      not a valid URL.
    - **401 Unauthorized:** The credentials you passed aren't valid.

Call URLs
---------

GET /call-url
~~~~~~~~~~~~~~

    **Requires authentication**

    List all user valid call-urls.

    Response from the server:

    The server should answer this with a 200 status code and a list of
    JSON objects with the following properties:

    - **callerId** The name of the person to whom the call-url has been issued ;
    - **expires** The date when the url will expire (the unix epoch, in
      seconds).
    - **timestamp** The date when the url has been created (the unix epoch, in
      seconds).

    Example::

       http GET localhost:5000/v1/call-url --verbose \
       --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        GET /v1/call-url HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0


        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 186
        Content-Type: application/json; charset=utf-8
        Date: Thu, 13 Nov 2014 16:19:59 GMT
        Server-Authorization: <stripped>
        Timestamp: 1415895599

        [
            {
                "callerId": "Natim",
                "expires": 1416499576,
                "timestamp": 1415894776
            }
        ]


    Potential HTTP error responses include:

    - **401 Unauthorized**: You need to authenticate to call this URL.
    - **503 Service Unavailable**: Something is wrong on the server side.


POST /call-url
~~~~~~~~~~~~~~

    **Requires authentication**

    Generates a call url for the given `callerId`. This is an URL the caller
    can click on in order to call the caller.

    Body parameters:

    - **callerId**, the caller (the person you will give the link to)
      identifier.
    - **expiresIn**, the number of hours the call-url will be valid for.
    - **issuer**, The friendly name of the issuer of the token.

    Optional parameters:

    - **subject**, The subject of the conversation.

    Response from the server:

    The server should answer this with a 200 status code and a JSON object
    with the following properties:

    - **callUrl** The call url;
    - **callToken** The call token;
    - **expiresAt** The date when the url will expire (the unix epoch, in
      seconds).

    Example::

       http POST localhost:5000/v1/call-url --verbose \
       callerId=Remy expiresIn=5 issuer=Alexis \
       --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        POST /v1/call-url HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Content-Length: 40
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "callerId": "Remy",
            "expiresIn": "5",
            "issuer": "Alexis",
            "subject": "MySubject"
        }

        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 186
        Content-Type: application/json; charset=utf-8
        Date: Wed, 16 Jul 2014 13:09:40 GMT
        Server-Authorization: <stripped>
        Timestamp: 1405516180

        {
            "callToken": "_nxD4V4FflQ",
            "callUrl": "http://localhost:3000/static/#call/_nxD4V4FflQ",
            "expiresAt": 1405534180
        }


    Potential HTTP error responses include:

    - **400 Bad Request:**  You forgot to pass the `callerId`, or it's not
      valid;
    - **401 Unauthorized**: You need to authenticate to call this URL.


PUT /call-url/{token}
~~~~~~~~~~~~~~~~~~~~~

    **Requires authentication**

    Updates data associated with an already created call-url.

    Body parameters:

    - **callerId**, the caller (the person you will give the link to)
      identifier. The callerId is supposed to be a valid email address.
    - **expiresIn**, the number of hours the call-url will be valid for.
    - **issuer**, The friendly name of the issuer of the token.

    Optional parameters:

    - **subject**, The subject of the conversation.

    Response from the server:

    The server should answer this with a 200 status code and a JSON object
    with the following properties:

    - **expiresAt** The date when the url will expire (the unix epoch, in
      seconds).

    Example::

        http PUT localhost:5000/v1/call-url/B65nvlGh8iM --verbose \
        issuer=Adam --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        PUT /v1/call-url/B65nvlGh8iM HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Content-Length: 18
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "issuer": "Adam",
            "subject": "MySubject2"
        }

        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 29
        Content-Type: application/json; charset=utf-8
        Date: Wed, 16 Jul 2014 14:16:54 GMT
        Server-Authorization: <stripped>
        Timestamp: 1405520214

        {
            "expiresAt": 1408112214
        }



DELETE /call-url/{token}
~~~~~~~~~~~~~~~~~~~~~~~~

    **Requires authentication**

    Delete a previously created call url. You need to be the user
    who generated this link in order to delete it.

    Example::

        http DELETE localhost:5000/v1/call-url/_nxD4V4FflQ --verbose \
        --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'


    .. code-block:: http

        DELETE /v1/call-url/_nxD4V4FflQ HTTP/1.1
        Accept: */*
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Content-Length: 0
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        HTTP/1.1 204 No Content
        Connection: keep-alive
        Date: Wed, 16 Jul 2014 13:12:46 GMT
        Server-Authorization: <stripped>


    Potential HTTP error responses include:

    - **400 Bad Request:**  The token you passed is not valid or expired.
    - **404 Not Found:**  The token you passed doesn't exist.

Calls
-----

GET /calls/{token}
~~~~~~~~~~~~~~~~~~

    Returns information about the token.

    - *token* is the token returned by the **POST** on **/call-url**.

    Response from the server:

    The server should answer this with a 200 status code and a JSON object
    with the following properties:

    - **calleeFriendlyName** the friendly name the creator of the call-url gave.
    - **urlCreationDate**, the unix timestamp when the url was created.

    Optional:

    - **subject**, the subject of the conversation.

    Example::

        http GET localhost:5000/v1/calls/3jKS_Els9IU --verbose

    .. code-block:: http

        GET /v1/calls/3jKS_Els9IU HTTP/1.1
        Accept: */*
        Accept-Encoding: gzip, deflate
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0


        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 30
        Content-Type: application/json; charset=utf-8
        Date: Wed, 16 Jul 2014 13:23:04 GMT
        ETag: W/"1e-2896316483"
        Timestamp: 1405516984

        {
            "calleeFriendlyName": "Alexis",
            "urlCreationDate": 1405517546,
            "subject": "MySubject"
        }

    Potential HTTP error responses include:

    - **400 Bad Request:**  The token you passed is not valid or expired.


POST /calls/{token}
~~~~~~~~~~~~~~~~~~~

    Creates a new incoming call for the given token. Gets tokens and session
    from the provider and does a simple push notification, then returns caller
    tokens.

    Body parameters:

    - **callType**, Specifies the type of media the remote party intends to
      send. Valid values are "audio" or "audio-video".

    Optional parameters:

    - **subject**, the subject of the conversation
    - **channel**, the TokBox channel to use for the call

    Channel can be one of:

    - **release**
    - **esr**
    - **beta**
    - **aurora**
    - **nightly**
    - **default**
    - **mobile** -- used for the Firefox OS Mobile client
    - **standalone** -- used for the standalone / "link-clicker" client

    Server should answer with a status of 200 and the following information in
    its body (json encoded):

    - **apiKey**, the provider public api Key.
    - **callId**, an unique identifier for the call;
    - **progressURL**, the location to reach for websockets;
    - **sessionId**, the provider session identifier;
    - **sessionToken**, the provider session token (for the caller);
    - **websocketToken**, the token to use when authenticating to the websocket.

    Example::

        http POST localhost:5000/v1/calls/QzBbvGmIZWU callType="audio-video" --verbose

    .. code-block:: http

        POST /v1/calls/QzBbvGmIZWU HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Content-Length: 27
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "callType": "audio-video",
            "channel": "nightly",
            "subject": "MySubject"
        }

        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 614
        Content-Type: application/json; charset=utf-8
        Date: Wed, 16 Jul 2014 13:37:39 GMT
        Timestamp: 1405517859

        {
            "apiKey": "44669102",
            "callId": "35e7c3a511f424d3b1d6fba442b3a9a5",
            "progressURL": "ws://localhost:5000/websocket",
            "sessionId": "1_MX40NDY2OTEwMn5-V2VkIEp1bCAxNiAwNjo",
            "sessionToken": "T1==cGFydG5lcl9pZD00NDY2OTEwMiZzaW",
            "websocketToken": "44ee04b9694ae121c03a1db685cfad6d"
        }

    (note that return values have been truncated for readability purposes.)

    Potential HTTP error responses include:

    - **400 Bad Request:**  The token you passed is not valid.
    - **410 Gone:** The token expired.

POST /calls
~~~~~~~~~~~

    **Requires authentication**

    Similar to *POST /calls/{token}*, it creates a new incoming call to a known
    identity. Gets tokens and session from the provider and does a simple push
    notification, then returns caller tokens.

    Body parameters:

    - **calleeId**, array of strings containing the identities of the
      receiver(s) of the call. These identities should be one of the valid Loop
      identities (Firefox Accounts email or MSISDN) and can belong to none, an
      unique or multiple Loop users.
      It can also be an object with two properties:

      - **phoneNumber** The phone number on a local form
      - **mcc** The current SIM card Mobile Country Code

      In that case, the server will try to convert the phoneNumber as
      an MSISDN identity

    - **callType**, Specifies the type of media the remote party intends to
      send. Valid values are "audio" or "audio-video".

    Optional parameters:

    - **subject**, the subject of the conversation
    - **channel**, the TokBox channel to use for the call

    Channel can be one of:

    - **release**
    - **esr**
    - **beta**
    - **aurora**
    - **nightly**
    - **default**
    - **mobile** -- used for the Firefox OS Mobile client
    - **standalone** -- used for the standalone / "link-clicker" client

    Server should answer with a status of 200 and the following information in
    its body (json encoded):

    - **apiKey**, the provider public api Key.
    - **callId**, an unique identifier for the call;
    - **progressURL**, the location to reach for websockets;
    - **sessionId**, the provider session identifier;
    - **sessionToken**, the provider session token (for the caller);
    - **websocketToken**, the token to use when authenticating to the websocket.

    Example::

        http POST localhost:5000/v1/calls --verbose \
        calleeId=alexis callType="audio-video" \
        --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        POST /v1/calls HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Content-Length: 27
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "callType": "audio-video"
            "calleeId": ["alexis@mozilla.com", "+34123456789"],
            "channel": "nightly",
            "subject": "MySubject"
        }

        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 614
        Content-Type: application/json; charset=utf-8
        Date: Wed, 16 Jul 2014 13:37:39 GMT
        Server-Authorization: <stripped>
        Timestamp: 1405517859

        {
            "apiKey": "44669102",
            "callId": "35e7c3a511f424d3b1d6fba442b3a9a5",
            "progressURL": "ws://localhost:5000/websocket",
            "sessionId": "1_MX40NDY2OTEwMn5-V2VkIEp1bCAxNiAwNjo",
            "sessionToken": "T1==cGFydG5lcl9pZD00NDY2OTEwMiZzaW",
            "websocketToken": "44ee04b9694ae121c03a1db685cfad6d"
        }

    (note that return values have been truncated for readability purposes.)

    Potential HTTP error responses include:

    - **400 Bad Request:**  You forgot to pass `calleeId` or is not valid.
    - **401 Unauthorized**: You need to authenticate to call this URL.


GET /calls?version=<version>
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    **Requires authentication**

    List incoming calls for the authenticated user since the given version.

    Querystring parameters:

    - **version**, the version simple push gave to the client when waking it
      up. Only calls that happened since this version will be returned.

    Server should answer with a status of 200 and a list of calls in its body.
    Each call has the following attributes:

    - **apiKey**, the provider public api Key.
    - **callId**, an unique identifier for the call.
    - **callType**, the call type ("audio" or "audio-video").
    - **progressURL**, the location to reach for websockets.
    - **sessionId**, the provider session identifier.
    - **sessionToken**, the provider session token (for the caller).
    - **websocketToken**, the token to use when authenticating to the websocket.

    Optional:

    - **subject**, the subject of the call

    In case of call initiated from an URL you will also have:

    - **callToken**, the call-url token used for this call.
    - **callUrl**, the call-url used for this call.
    - **urlCreationDate**, the unix timestamp when the used call-url was created.

    .. code-block:: http

        GET /v1/calls?version=0 HTTP/1.1
        Accept: */*
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 1785
        Content-Type: application/json; charset=utf-8
        Date: Wed, 16 Jul 2014 14:10:38 GMT
        ETag: W/"6f9-2990115590"
        Server-Authorization: <stripped>
        Timestamp: 1405519838

        {
            "calls": [
                {
                    "apiKey": "44669102",
                    "callId": "6744b8919d7d74e8c0b39590aa183565",
                    "callToken": "QzBbvGmIZWU",
                    "callUrl": "http://localhost:3000/static/#call/QzBbvGmIZWU",
                    "call_url": "http://localhost:3000/static/#call/QzBbvGmIZWU",
                    "callerId": "alexis",
                    "progressURL": "ws://localhost:5000/websocket",
                    "sessionId": "2_MX40NDY2OTEwMn5-V2VkIEp1bCAxNiAwNzoxMDoyMCBQRFQgMjAxNH4wLj",
                    "sessionToken": "T1==cGFydG5lcl9pZD00NDY2OTEwMiZzaWc9NzMyMGVmZjY1YWU0ZmFkZTY1NmU0",
                    "urlCreationDate": 1405517546,
                    "websocketToken": "a2fc1ee029169b62b08a4ba87c328d71",
                    "subject": "MySubject"
                }
            ]
        }


    Potential HTTP error responses include:

    - **400 Bad Request:**  The version you passed is not valid.


Rooms
-----

Some endpoints requires **owner** authentication, it is the account
used to create the room on the ``POST /rooms``.

On these endpoints only the owner can perform the action on the room.

Some endpoints requires **participants** authentification, it is
either the Hawk Session used to join the room using the :ref:`Hawk
Authorization scheme <hawk-authentication>` or the sessionToken the
user has got when joining anonymously using the :ref:`Basic Auth
Authorization scheme <basic-auth-authorization>`.

.. _basic-auth-authorization:

Basic Auth Authorization
~~~~~~~~~~~~~~~~~~~~~~~~

In that case, just use the room participant sessionToken as a Basic
Auth username with no password.

    http POST localhost:5000/rooms/:token --auth "_sessionToken_:"

    Authorization: Basic X3Nlc3Npb25Ub2tlbl86

POST /rooms
~~~~~~~~~~~

    **Requires owner authentication**

    Creates a new room

    Request body parameters:

    - **roomName**, The name of the room.
    - **roomOwner**, The room owner name.
    - **maxSize**, The maximum number of people the room can handle.

    Optional parameter:

    - **expiresIn**, the number of hours for which the room will exist.

    Response body parameters:

    - **roomToken**, The token used to identify the created room.
    - **roomUrl**, A URL that can be given to other users to allow them to join the room.
    - **expiresAt**, The date after which the room will no longer be
      valid (in seconds since the Unix epoch).

    Potential HTTP error responses include:

    - **400 Bad Request:**  Missing or invalid body parameters

    Example::

        http POST localhost:5000/v1/rooms --verbose \
        roomName="My Room" roomOwner="Natim" maxSize=5 \
        --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        POST /rooms HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Content-Length: 61
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "maxSize": "5",
            "roomName": "My Room",
            "roomOwner": "Natim"
        }

        HTTP/1.1 201 Created
        Connection: keep-alive
        Content-Length: 109
        Content-Type: application/json; charset=utf-8
        Date: Mon, 10 Nov 2014 14:29:41 GMT
        Server: nginx/1.6.1
        Server-Authorization: <stripped>

        {
            "expiresAt": 1418221780,
            "roomToken": "pPVoaqiH89M",
            "roomUrl": "http://localhost:3000/static/#rooms/pPVoaqiH89M"
        }


PATCH /rooms/:token
~~~~~~~~~~~~~~~~~~~

    **Requires owner authentication**

    Updates an existing room

    Optional request body parameters:

    - **roomName**, The name of the room.
    - **roomOwner**, The room owner name.
    - **maxSize**, The maximum number of people the room can handle.
    - **expiresIn**, the number of hours for which the room will exist.

    You only need set the body parameters you want to update.

    Response body parameters:

    - **expiresAt**, The date after which the room will no longer be
      valid (in seconds since the Unix epoch)

    Potential HTTP error responses include:

    - **400 Bad Request:**  Missing or invalid body parameters

    Example::

        http PATCH localhost:5000/v1/rooms/pPVoaqiH89M --verbose \
        roomName="My Room" roomOwner="Natim" maxSize=5 \
        --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        PATCH /rooms/pPVoaqiH89M HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Content-Length: 61
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "maxSize": "5",
            "roomName": "My Room",
            "roomOwner": "Natim"
        }

        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 24
        Content-Type: application/json; charset=utf-8
        Date: Mon, 10 Nov 2014 14:33:19 GMT
        Server: nginx/1.6.1
        Server-Authorization: <stripped>
        Timestamp: 1415629999

        {
            "expiresAt": 1418221999
        }


DELETE /rooms/:token
~~~~~~~~~~~~~~~~~~~~

    **Requires owner authentication**

    Deletes an existing room.

    Example::

        http DELETE localhost:5000/v1/rooms/LURlwjMc8wI --verbose \
        --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        DELETE /rooms/LURlwjMc8wI HTTP/1.1
        Accept: */*
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Content-Length: 0
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0


        HTTP/1.1 204 No Content
        Connection: keep-alive
        Date: Mon, 10 Nov 2014 14:35:37 GMT
        Server: nginx/1.6.1
        Server-Authorization: <stripped>


POST /rooms/:token
~~~~~~~~~~~~~~~~~~

This endpoint handles three kinds of actions:

- **join**, A new participant joins the room.
- **refresh**, A participant notifies she is still in the room.
- **leave**, A participant notifies she is leaving the room.


Joining the room
""""""""""""""""

    Request body parameters:

    - **action**, Should be "join" in that case.
    - **displayName**, The participant friendly name for this room.
    - **clientMaxSize**, Maximum number of room participants the
      user's client is capable of supporting.

    Response body parameters:

    - **apiKey**, The TokBox public api key.
    - **sessionId**, The TokBox session identifier (identifies the room).
    - **sessionToken**, The TokBox session token (identifies the room participant).
    - **expires**, The number of seconds within which the client must
      send another POST to this endpoint with the refresh action to
      remain a participant in this room.

    Potential HTTP error responses include:

    - **400 Bad Request:**  Missing or invalid body parameters

    Example::

        http POST localhost:5000/v1/rooms/pPVoaqiH89M --verbose \
        action=join displayName=Natim clientMaxSize=5 \
        --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        POST /rooms/pPVoaqiH89M HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Content-Length: 64
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "action": "join",
            "clientMaxSize": "5",
            "displayName": "Natim"
        }

        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 461
        Content-Type: application/json; charset=utf-8
        Date: Mon, 10 Nov 2014 14:39:12 GMT
        Server: nginx/1.6.1
        Server-Authorization: <stripped>
        Timestamp: 1415630346

        {
            "apiKey": "44669102",
            "expires": 300,
            "sessionId": "1_XM40NYDO2TEwMI5-MTQxNTYyOTc4MTIzOH5PaGxlZlNRTXdqVi9XRGUIel8jZWh0KZz-VH4",
            "sessionToken": "T1==cGFydG5lcl9pZD00NDY2OTEw...=="
        }


Refreshing membership in a room
"""""""""""""""""""""""""""""""

    **Requires participant authentication**


    Request body parameters:

    - **action**, Should be "refresh" in that case.

    On success, the endpoint will return a **204 No Content** response.

    Potential HTTP error responses include:

    - **400 Bad Request:**  Missing or invalid body parameters

    Example::

        http POST localhost:5000/v1/rooms/pPVoaqiH89M --verbose \
        action=refresh \
        --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        POST /rooms/pPVoaqiH89M HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Content-Length: 21
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "action": "refresh"
        }

        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 461
        Content-Type: application/json; charset=utf-8
        Date: Mon, 10 Nov 2014 14:40:06 GMT
        Server: nginx/1.6.1
        Server-Authorization: <stripped>
        Timestamp: 1415630346

        {
            "expires": 300
        }


Leaving the room
""""""""""""""""

    Request body parameters:

    - **action**, Should be "leave" in that case.

    The endpoint will return a **204 No Content** response.

    Potential HTTP error responses include:

    - **400 Bad Request:**  Missing or invalid body parameters

    Example::

        http POST localhost:5000/v1/rooms/pPVoaqiH89M --verbose \
        action=leave \
        --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        POST /rooms/pPVoaqiH89M HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Content-Length: 19
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "action": "leave"
        }

        HTTP/1.1 204 No Content
        Connection: keep-alive
        Date: Mon, 10 Nov 2014 14:48:24 GMT
        Server: nginx/1.6.1
        Server-Authorization: <stripped>


GET /rooms/:token
~~~~~~~~~~~~~~~~~

    **Requires participant authentication**

    Retrieves information about the room.

    Response body parameters:

    - **roomToken**, The token used to identify this room.
    - **roomName**, The name of the room.
    - **roomUrl**, A URL that can be given to other users to allow them to join the room.
    - **roomOwner**, The user-friendly display name indicating the name of the room's owner.
    - **maxSize**, The maximum number of users allowed in the room at
      one time (as configured by the room owner).
    - **clientMaxSize**, The current maximum number of users allowed
      in the room, as constrained by the clients currently
      participating in the session. If no client has a supported size
      smaller than "maxSize", then this will be equal to
      "maxSize". Under no circumstances can "clientMaxSize" be larger
      than "maxSize".
    - **creationTime**, The time (in seconds since the Unix epoch) at which the room was created.
    - **expiresAt**, The time (in seconds since the Unix epoch) at which the room goes away.
    - **participants**, An array containing a list of the current room
      participants. :ref:`More information about the participant properties <participant-information>`.

    - **ctime**, The time, in seconds since the Unix epoch, that any
      of the following happened to the room:

      - The room was created
      - The owner modified its attributes with "PATCH /rooms/{token}"
      - A user joined the room
      - A user left the room

    Example::

        http GET localhost:5000/v1/rooms/pPVoaqiH89M --verbose \
        --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        GET /rooms/pPVoaqiH89M HTTP/1.1
        Accept: */*
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0


        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 284
        Content-Type: application/json; charset=utf-8
        Date: Mon, 10 Nov 2014 14:52:20 GMT
        ETag: W/"11c-d426a3d5"
        Server: nginx/1.6.1
        Server-Authorization: <stripped>
        Timestamp: 1415631140

        {
            "clientMaxSize": 5,
            "creationTime": 1415629780,
            "ctime": 1415631010,
            "expiresAt": 1418221999,
            "maxSize": 5,
            "participants": [
                {
                    "displayName": "Natim",
                    "roomConnectionId": "0bc7fa46-3df0-4621-b904-afdd2390d9ef",
                    "owner": true,
                    "account": "natim@example.com"
                }
            ],
            "roomName": "My Room",
            "roomOwner": "Natim",
            "roomUrl": "http://locahost:3000/#/rooms/pPVoaqiH89M"
        }


GET /rooms
~~~~~~~~~~

    **Requires owner authentication**

    Retrieves a list of rooms owned by the owner.

    The response is a list of objects with this information:

    - **roomToken**, The token used to identify this room.
    - **roomName**, The name of the room.
    - **roomUrl**, A URL that can be given to other users to allow them to join the room.
    - **roomOwner**, The user-friendly display name indicating the name of the room's owner.
    - **maxSize**, The maximum number of users allowed in the room at
      one time (as configured by the room owner).
    - **clientMaxSize**, The current maximum number of users allowed
      in the room, as constrained by the clients currently
      participating in the session. If no client has a supported size
      smaller than "maxSize", then this will be equal to
      "maxSize". Under no circumstances can "clientMaxSize" be larger
      than "maxSize".
    - **creationTime**, The time (in seconds since the Unix epoch) at which the room was created.
    - **expiresAt**, The time (in seconds since the Unix epoch) at which the room goes away.
    - **participants**, An array containing a list of the current room
      participants. :ref:`More information about the participant properties <participant-information>`.

    - **ctime**, The time, in seconds since the Unix epoch, that any
      of the following happened to the room:

      - The room was created
      - The owner modified its attributes with "PATCH /rooms/{token}"
      - A user joined the room
      - A user left the room

    Example::

        http GET localhost:5000/v1/rooms --verbose \
        --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        GET /rooms/ HTTP/1.1
        Accept: */*
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0


        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Length: 312
        Content-Type: application/json; charset=utf-8
        Date: Mon, 10 Nov 2014 14:50:12 GMT
        ETag: W/"138-9bb2c1c"
        Server: nginx/1.6.1
        Server-Authorization: <stripped>
        Timestamp: 1415631012

        [
            {
                "clientMaxSize": 5,
                "creationTime": 1415629780,
                "ctime": 1415631010,
                "expiresAt": 1418221999,
                "maxSize": 5,
                "participants": [
                    {
                      "displayName": "Natim",
                      "roomConnectionId": "0bc7fa46-3df0-4621-b904-afdd2390d9ef",
                      "owner": true,
                      "account": "natim@example.com"
                    }
                ],
                "roomName": "My Room",
                "roomOwner": "Natim",
                "roomToken": "pPVoaqiH89M",
                "roomUrl": "http://localhost:3000/static/#rooms/pPVoaqiH89M"
            }
        ]


.. _participant-information:

Participant information
~~~~~~~~~~~~~~~~~~~~~~~

    When retrieving the room information you get a list of participants.
    It is a list of objects with these properties:

    - **displayName**, The user-friendly name that should be displayed for this participant.
    - **account**, If the user is logged in, this is the FxA account
      name or MSISDN that was used to authenticate the user for this
      session.
    - **owner**, if the user is also the owner of the room, this
      property will be true, it will be false otherwise.
    - **roomConnectionId**, An id, unique within the room for the
      lifetime of the room, used to identify a partcipant for the
      duration of one instance of joining the room. If the user
      departs and re-joins, this id will change.


Account and Session
-------------------

DELETE /account
~~~~~~~~~~~~~~~

    **Requires authentication**

    Deletes the current account and all data associated to it.

    Example::

        http DELETE localhost:5000/v1/account --verbose \
        --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        DELETE /v1/account HTTP/1.1
        Accept: */*
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Content-Length: 0
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        HTTP/1.1 204 No Content
        Connection: keep-alive
        Date: Wed, 16 Jul 2014 13:03:39 GMT
        Server-Authorization: <stripped>


DELETE /session
~~~~~~~~~~~~~~~

    **Requires authentication**

    Deletes the current session.

    This should be used to clear the hawk session of a Firefox Account
    user. You should not attempt to call this endpoint with a
    non-firefox account session, since it would mean as a client you
    could not attach a session anymore.

    In case you want to destroy a non-FxA session, please use the
    DELETE /account endpoint.

    Example::

        http DELETE localhost:5000/v1/session --verbose \
        --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        DELETE /v1/session HTTP/1.1
        Accept: */*
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Content-Length: 0
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        HTTP/1.1 204 No Content
        Connection: keep-alive
        Date: Wed, 16 Jul 2014 13:03:39 GMT
        Server-Authorization: <stripped>

    Potential HTTP error responses include:

    - **403 Forbidden:** If you remove this session you will loose
      access to your loop-server data because you will not be able to
      link them to a new session. Use DELETE /account instead.


Integration with Firefox Accounts using OAuth
---------------------------------------------

A few endpoints are available for integration with Firefox Accounts. This is
the prefered way to login with your Firefox Accounts for loop. For more
information on how to integrate with Firefox Accounts, `have a look at the
Firefox Accounts documentation on MDN
<https://developer.mozilla.org/en-US/Firefox_Accounts#Login_with_the_FxA_OAuth_HTTP_API>`_

POST /fxa-oauth/params
~~~~~~~~~~~~~~~~~~~~~~

    **Requires authentication**

    Provide the client with the parameters needed for the OAuth dance.

    - **client_id**, the client id used by the server;
    - **content_uri**, URI of the content server (to get account information);
    - **oauth_uri**, URI of the OAuth server;
    - **redirect_uri**, URI where the client should redirect once authenticated;
    - **scope**, The scope of the token returned;
    - **state**, A nonce used to check that the session matches.

    ::

        http POST http://localhost:5000/v1/fxa-oauth/params --verbose \
        --auth-type=hawk --auth='ca13d91d1d4b67edf0b9523a2867b3d1b74eb63823732c441992f813f9da1f76:' --json

    .. code-block:: http

        POST /v1/fxa-oauth/params HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        HTTP/1.1 200 OK
        Connection: keep-alive
        Server-Authorization: <stripped>
        Timestamp: 1409052727

        {
            "client_id": "263ceaa5546dce83",
            "content_uri": "https://accounts.firefox.com",
            "oauth_uri": "https://oauth.accounts.firefox.com/v1",
            "redirect_uri": "urn:ietf:wg:oauth:2.0:fx:webchannel",
            "scope": "profile",
            "state": "b56b3753c15efdcae80ea208134ecd6ae97f27027ce9bb11f7c333be6ea7029c"
        }


GET /fxa-oauth/token
~~~~~~~~~~~~~~~~~~~~

    **Requires authentication**

    Returns the current status of the hawk session (e.g. if it's authenticated or not)::

        http GET http://localhost:5000/v1/fxa-oauth/token  --verbose \
        --auth-type=hawk --auth='ca13d91d1d4b67edf0b9523a2867b3d1b74eb63823732c441992f813f9da1f76:' --json

    If the current session is authenticated using OAuth, it returns it
    in the **access_token** attribute.

    .. code-block:: http

        GET /v1/fxa-oauth/token HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        HTTP/1.1 200 OK
        Connection: keep-alive
        Content-Type: application/json; charset=utf-8
        Server-Authorization: <stripped>
        Timestamp: 1409058431


POST /fxa-oauth/token
~~~~~~~~~~~~~~~~~~~~~

    **Requires authentication**

    Trades an OAuth code with an oauth bearer token::

        http POST http://localhost:5000/v1/fxa-oauth/token --verbose \
        state=b56b3753c15efdcae80ea208134ecd6ae97f27027ce9bb11f7c333be6ea7029c \
        code=12345 \
        --auth-type=hawk --auth='ca13d91d1d4b67edf0b9523a2867b3d1b74eb63823732c441992f813f9da1f76:' --json

    Checks the validity of the given code and state and exchange it with a
    bearer token with the OAuth servers.

    The token is returned in the **access_token** attribute. A few additional
    parameters are returned:

    - **scope** the scope of the token;
    - **token_type** the type of the token returned (here, it will be
      "bearer").

Error Responses
---------------

All errors are also returned, wherever possible, as json responses
with a code, errno and error message.

Error status codes and codes and their corresponding outputs are:

- **404** : unknown URL, or unsupported application.
- **400** : malformed request. Possible causes include a missing
  option, bad values or malformed json.
- **401** : you need to be authenticated
- **403** : you are authenticated but don't have access to the resource you are
            requesting.
- **405** : unsupported method
- **406** : unacceptable - the client asked for an Accept we don't support
- **503** : service unavailable (provider or database backends may be down)

Also the associated errno can be one of:

- **105 INVALID_TOKEN**: This come with a 404 on a wrong call-url token;
- **106 BADJSON**: This come with a 406 if the sent JSON is not parsable;
- **107 INVALID_PARAMETERS**: This come with a 400 and describe
  invalid parameters with a reason;
- **108 MISSING_PARAMETERS**: This come with a 400 and list all missing parameters;
- **110 INVALID_AUTH_TOKEN**: This come with a 401 and define a problem during Auth;
- **111 EXPIRED**: This come with a 410 and define a EXPIRE ressource;
- **113 REQUEST_TOO_LARGE**: This come with a 400 and define a too large request;
- **114 INVALID_OAUTH_STATE**: This come with a 400 and tells the oauth state is invalid;
- **201 BACKEND**: This come with a 503 when a third party is not available at the moment.


.. _websockets-apis:

Websockets APIs
===============

During the setup phase of a call, the websocket protocol is used to
let clients broadcast their state to other clients and to listen to
changes.

The client will establish a WebSockets connection to the resource
indicated in the "progressURL" when it receives it. The client never
closes this connection; that is the responsibility of the server. The
times at which the server closes the connection are detailed below. If
the server sees the client close the connection, it assumes that the
client has failed, and informs the other party of such call failure.

For forward compatibility purposes:

* Unknown fields in messages are ignored
* Unknown message types received by the client (indicating an earlier release)
  result in the client sending an "error" message ({"messageType": "error",
  "reason": "unknown message"}). The call setup should continue.
* Unknown message types received by the server result in the server sending an
  "error" message (as above); however, since this situation can only arise due to
  a misimplemented client or an out-of-date server, it results in call setup
  failure. The server closes the connection.

Call Setup States
-----------------

Call setup goes through the following states:

.. image:: /images/loop-call-setup-state.png

Call Progress Protocol
----------------------

Initial Connection (hello)
~~~~~~~~~~~~~~~~~~~~~~~~~~

Upon connecting to the server, the client sends an immediate "hello" message,
which serves two purposes: it identifies the call that the progress channel
corresponds to (using the "callId"), as well as authenticating the connecting
user, so that they can be verified to be authorized to view/impact the call
setup state.

Note that the callId with which this connection is to be associated is encoded
as a component of the WSS URL.

UA -> Server::

   {
     "messageType": "hello",
     "auth": "''<authentication information>''"
   }


* `auth`: Information to authenticate the user, so that they can be verified to
  be authorized to access call setup information. This is the `websocketToken`
  returned by a POST to /calls/{token}, POST /calls and GET /calls.

If the hello is valid (the callId is known, the auth information is valid, and
the authenticated user is a party to the call), then the server responds with a
"hello." This "hello" includes the current call setup state.

Server -> UA::

   {
     "messageType": "hello",
     "state": "alerting"
     // may contain "reason" field for certain states.
   }

* `state`: See states in "progress", below.

If the hello is invalid for any reason, then the server sends an "error"
message, as follows. It then closes the connection.

Server -> UA::

   {
     "messageType": "error",
     "reason": "unknown callId"
   }

`reason`: The reason the hello was rejected:

* `unknown callId`
* `invalid authentication` - The auth information was not valid
* `unauthorized` - The auth information was valid, but did not match the
   indicated callId

Call Progress State Change (progress)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The server informs users of the current state of call setup. The state sent to
both parties ''is always the same state''. So, for example, when a user rejects
a call, he will receive a "progress" message with a state of "terminated" and a
reason of "rejected."

Server -> UA::

   {
     "messageType": "progress",
     "state": "alerting"
     // may contain optional "reason" field for certain events.
   }

Defined states are:

* `init`: The call is starting, and the remote party is not yet being alerted.
* `alerting`: The called party is being alerted (triggered by remote party
   sending a "hello" message).
* `terminated`: The call is no longer being set up. After sending a
  "terminated" message, the server closes the WebSockets connection. This message
  will include a "reason" field with one of the reason values described below.
* `connecting`: The called party has indicated that he has answered the call,
  but the media is not yet confirmed
* `half-connected`: One of the two parties has indicated successful media set
  up, but the other has not yet.
* `connected`: Both endpoints have reported successfully establishing media.
  After sending a "connected" message, the server closes the WebSockets
  connection.

Client Action (action)
~~~~~~~~~~~~~~~~~~~~~~

During call setup, clients send progress information about their own state so
that it can be reflected in the call state.

UA -> Server::

   {
     "messageType": "action",
     "event": "accept"
     // May contain "reason" field for certain events
   }

Defined event types are:

* `accept`: Only sent by called party. The user has answered this call. This is
  sent before the called party attempts to set up the media.
* `media-up`: Sent by both parties. Communications have been successfully
  established.
* `terminate`: Sent by both parties. Ends attempt to set up call. Includes a
  "reason" field with one of values detailed below.

Termination Reasons
-------------------

The following reasons appear in "action"/"terminate" and "progress" /
"terminated" messages. The "√" columns indicate whether the indicated element
is permitted to generate the reason. When generated a "terminated" message as
the result of receiving a "terminate" action from either client, the server
will copy the reason code from the "terminate" action message into all
resulting "terminated" progress messages, ''even if it does not recognize the
reason code''.

To provide for forwards compatibility, clients must be prepared to process
"terminated" progress messages with unknown reason codes. The reaction to this
situation should be the display of a generic "call setup failed" message.

If the server receives an action of "terminate" with a reason it does not
recognize, it copies that reason into the resulting "terminated" message.

==================   ======    ======    ======    ========================================
    Reason           Caller    Callee    Server                    Note
==================   ======    ======    ======    ========================================
reject                         √                   The called user has declined the call.
busy                           √                   The user is logged in, but cannot answer
                                                   the call due to some current state
                                                   (e.g., DND, in another call).
timeout                        √         √         The call setup has timed out (The
                                                   called party's client has exceeded the
                                                   amount of time it is willing to alert
                                                   the user, or one of the server's timers
                                                   expired)
cancel                √                            The calling party has cancelled a pending
                                                   call.
media-fail                     √                   The called user has declined the call.
user-unknown                             √         The indicated user id does not exist.
closed                                   √         The other user's WSS connection closed
                                                   unexpectedly.
==================   ======    ======    ======    ========================================

Timer Supervision
-----------------

Server Timers
~~~~~~~~~~~~~

The server uses three timers to ensure that the call created by a setup attempt
is cleaned up in a timely fashion.

Supervisory Timer
"""""""""""""""""

After responding to a ```POST /call/{token}``` or ```POST /call/user```
message, the server starts a supervisory timer of 10 seconds.

* If the calling user does not connect and send a "hello" in this time period,
  the server considers the call to be failed. The called user, if connected,
  will receive a "progress"/"terminated" message with a reason of "timeout".
* If the called user does not connect and send a "hello" in this time period,
  the server considers the call to be failed. The calling user, if connected,
  will receive a "progress"/"terminated" message with a reason of "timeout".

Ringing Timer
"""""""""""""

Upon receiving a "hello" from the called user, the server starts a ringing
timer of 30 seconds. If the called user does not send an "accept" message in
this time period, then both parties will receive a "progress"/"terminated"
message with a reason of "timeout".

Connection Timer
""""""""""""""""

Upon receiving an "accept" from the called user, the server starts a connection
timer of 10 seconds. If the call setup state does not reach "connected" in this
time period, then both parties will receive a "progress"/"terminated" message
with a reason of "timeout".

Client Timers
~~~~~~~~~~~~~

Response Timer
""""""""""""""

Every client message triggers a response from the server: "hello" results in
"hello" or "error"; and "action" will always cause a corresponding "progress"
message to be sent. When the client sends a message, it sets a timer for 5
seconds. If the server does not respond in that time period, it disconnects
from the server and considers the call failed.

Media Setup Timer
"""""""""""""""""

After sending a "media-up" action, the client sets a timer for 10 seconds. If
the server does not indicate that the call setup has entered the "connected"
state before the timer expires, the client disconnects from the server and
considers the call failed.

Alerting Timer
""""""""""""""

We may wish to let users configure the maximum amount of time the call is
allowed to ring (up to 30 seconds) before it considers it unanswered. This
timer would start as soon as user alerting begins. If it expires before the
call is set up, then the called party sends a "action"/"disconnect" message
with a reason of "timeout."
