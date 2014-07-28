====================
Loop Server API v1.0
====================

This document is based on the current status of the server. All the examples
had been done with real calls. It doesn't reflect any future implementation and
tries to stick with the currently deployed version.

This document describes the HTTP API and the Websockets API.

HTTP APIs
=========

.. note::

    Unless stated otherwise, all APIs are using application/json for the requests
    and responses content types. Parameters for the GET requests are form
    encoded (?key=value&key2=value2)

To ease testing, you can use `httpie <https://github.com/jkbr/httpie>`_ in
order to make requests. Examples of use with httpie are provided when possible.
In order to authenticate with hawk, you'll need to install the `requests-hawk
module <https://github.com/mozilla-services/requests-hawk>`_

Authentication
--------------

To deal with authentication, the Loop server uses `Hawk
<https://github.com/hueniverse/hawk>`_ sessions. When you
register, you can do so with different authentications schemes, but you are
always given an hawk session back, that you should use when requesting the
endpoints which need authentication.

Derive hawk credentials from the hawk session token
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When authenticating using the `/register` endpoint, you will be given an hawk
session token in the `Hawk-Session-Token` header.

In order to get the hawk credentials to use on the client you will need to:

1. Do an `HKDF derivation <http://en.wikipedia.org/wiki/HKDF>`_ on the given
   session token. You'll need to use the following parameters:

   key_material = HKDF(hawk_session, "", 'identity.mozilla.com/picl/v1/sessionToken', 32*3)

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
- Wtih python:
  https://github.com/mozilla-services/loop-server/blob/master/loadtests/loadtest.py#L99-L122

APIs
----

GET /
~~~~~

    Displays version information, for instance::

       http GET localhost:5000 --verbose

    .. code-block:: http

        GET / HTTP/1.1
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

        http POST localhost:5000/registration simplePushURL=https://push.services.mozilla.com/update/MGlYke2SrEmYE8ceyu --verbose

    .. code-block:: http

        POST /registration HTTP/1.1
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

    Unregister a given simple push-url from the loop server.

    Body parameters:

    - **simplePushURL**, the simple-push endpoint url as defined in
      https://wiki.mozilla.org/WebAPI/SimplePush#Definitions

    Example::

      http DELETE localhost:5000/registration simplePushURL=https://test --verbose --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        DELETE /registration HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: <Stripped>
        Content-Length: 35
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "simplePushURL": "https://test"
        }

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


POST /call-url
~~~~~~~~~~~~~~

    **Requires authentication**

    Generates a call url for the given `callerId`. This is an URL the caller
    can click on in order to call the caller.

    Body parameters:

    - **callerId**, the caller (the person you will give the link to)
      identifier. The callerId is supposed to be a valid email address.
    - **expiresIn**, the number of hours the call-url will be valid for.
    - **issuer**, The friendly name of the issuer of the token.

    Response from the server:

    The server should answer this with a 200 status code and a JSON object
    with the following properties:

    - **callUrl** The call url;
    - **callToken** The call token;
    - **expiresAt** The date when the url will expire (the unix epoch, in
      seconds).

    Example::

       http POST localhost:5000/call-url callerId=Remy expiresIn=5 issuer=Alexis --verbose --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        POST /call-url HTTP/1.1
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
            "issuer": "Alexis"
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

    Response from the server:

    The server should answer this with a 200 status code and a JSON object
    with the following properties:

    - **expiresAt** The date when the url will expire (the unix epoch, in
      seconds).

    Example::

        http PUT localhost:5000/call-url/B65nvlGh8iM issuer=Adam --verbose --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'                                                                                                    PUT /call-url/B65nvlGh8iM HTTP/1.1

    .. code-block:: http

        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: <stripped>
        Content-Length: 18
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "issuer": "Adam"
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

        http DELETE localhost:5000/call-url/_nxD4V4FflQ --verbose --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'


    .. code-block:: http

        DELETE /call-url/_nxD4V4FflQ HTTP/1.1
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


GET /calls/{token}
~~~~~~~~~~~~~~~~~~

    Returns information about the token.

    - *token* is the token returned by the **POST** on **/call-url**.

    Response from the server:

    The server should answer this with a 200 status code and a JSON object
    with the following properties:

    - **calleeFriendlyName** the friendly name the creator of the call-url gave.
    - **urlCreationDate**, the unix timestamp when the url was created.

    Example::

        http GET localhost:5000/calls/3jKS_Els9IU --verbose

    .. code-block:: http

        GET /calls/3jKS_Els9IU HTTP/1.1
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
            "urlCreationDate": 1405517546
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

    Server should answer with a status of 200 and the following information in
    its body (json encoded):

    - **apiKey**, the provider public api Key.
    - **callId**, an unique identifier for the call;
    - **progressURL**, the location to reach for websockets;
    - **sessionId**, the provider session identifier;
    - **sessionToken**, the provider session token (for the caller);
    - **websocketToken**, the token to use when authenticating to the websocket.

    Example::

        http POST localhost:5000/calls/QzBbvGmIZWU callType="audio-video" --verbose

    .. code-block:: http

        POST /calls/QzBbvGmIZWU HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Content-Length: 27
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "callType": "audio-video"
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
    - **callType**, Specifies the type of media the remote party intends to
      send. Valid values are "audio" or "audio-video".

    Server should answer with a status of 200 and the following information in
    its body (json encoded):

    - **apiKey**, the provider public api Key.
    - **callId**, an unique identifier for the call;
    - **progressURL**, the location to reach for websockets;
    - **sessionId**, the provider session identifier;
    - **sessionToken**, the provider session token (for the caller);
    - **websocketToken**, the token to use when authenticating to the websocket.

    Example::

        http POST localhost:5000/calls calleeId=alexis callType="audio-video" --verbose --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        POST /calls HTTP/1.1
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

    In case of call initiated from an URL you will also have:

    - **callToken**, the call-url token used for this call.
    - **callUrl**, the call-url used for this call.
    - **urlCreationDate**, the unix timestamp when the used call-url was created.

    .. code-block:: http

        GET /calls?version=0 HTTP/1.1
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
                    "websocketToken": "a2fc1ee029169b62b08a4ba87c328d71"
                }
            ]
        }


    Potential HTTP error responses include:

    - **400 Bad Request:**  The version you passed is not valid.

DELETE /account
~~~~~~~~~~~~~~~

    **Requires authentication**

    Deletes the current account and all data associated to it.

    Example::

        http DELETE localhost:5000/account --verbose --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        DELETE /account HTTP/1.1
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
- **107 INVALID_PARAMETERS**: This come with a 400 and describe invalid parameters with a reason;
- **108 MISSING_PARAMETERS**: This come with a 400 and list all missing parameters;
- **110 INVALID_AUTH_TOKEN**: This come with a 401 and define a problem during Auth;
- **111 EXPIRED**: This come with a 410 and define a EXPIRE ressource;
- **113 REQUEST_TOO_LARGE**: This come with a 400 and define a too large request;
- **201 BACKEND**: This come with a 503 when a third party is not available at the moment.


Websockets APIs
===============

During the setup phase of a call, the websocket protocol is used to let clients broadcast their state to other clients and to listen to changes.

The client will establish a WebSockets connection to the resource indicated in the "progressURL" when it receives it. The client never closes this connection; that is the responsibility of the server. The times at which the server closes the connection are detailed below. If the server sees the client close the connection, it assumes that the client has failed, and informs the other party of such call failure.

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
unregistered                             √         The called user does not have any
                                                   registered push server endpoints.
user-unknown                             √         The indicated user id does not exist.
connection-failure                       √         The other user's WSS connection closed
                                                   unexpectedly.
answered-elsewhere                       √         When the called user has more than one
                                                   device alerting at the same time and
                                                   accepts on one device, a "terminated"
                                                   with this reason code is sent to all
                                                   other devices that had been alerting.
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
