.. _http-apis:

HTTP APIs
#########

.. note::

    Unless stated otherwise, all APIs are using application/json for the requests
    and responses content types. Parameters for the GET requests are form
    encoded (?key=value&key2=value2)

To ease testing, you can use `httpie <https://github.com/jkbr/httpie>`_ in
order to make requests. Examples of use with httpie are provided when possible.
In order to authenticate with hawk, you'll need to install the `requests-hawk
module <https://github.com/mozilla-services/requests-hawk>`_

.. contents::

Versioning
==========

The current API is versioned, using only a major version. All the endpoints for
version 1 are prefixed by `/v1/`. In case you don't specify the prefix, your
requests will be redirected automatically with an http `307` status.


Authentication
==============

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
===================================================

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

HTTP API - Reference
====================


GET /
-----

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
-----------------------

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


POST /registration
------------------

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

        http POST localhost:5000/v1/registration --verbose\
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
--------------------

    **Requires authentication**

    Unregister a given simple push-url from the loop server.

    Body or querystring parameters:

    - **simplePushURL**, the simple-push endpoint url as defined in
      https://wiki.mozilla.org/WebAPI/SimplePush#Definitions

    Example::

      http DELETE localhost:5000/v1/registration --verbose\
      simplePushURL=https://test\
      --auth-type=hawk --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        DELETE /v1/registration HTTP/1.1
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
--------------

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

       http POST localhost:5000/v1/call-url --verbose\
       callerId=Remy expiresIn=5 issuer=Alexis\
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
---------------------

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

        http PUT localhost:5000/v1/call-url/B65nvlGh8iM --verbose\
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
------------------------

    **Requires authentication**

    Delete a previously created call url. You need to be the user
    who generated this link in order to delete it.

    Example::

        http DELETE localhost:5000/v1/call-url/_nxD4V4FflQ --verbose\
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


GET /calls/{token}
------------------

    Returns information about the token.

    - *token* is the token returned by the **POST** on **/call-url**.

    Response from the server:

    The server should answer this with a 200 status code and a JSON object
    with the following properties:

    - **calleeFriendlyName** the friendly name the creator of the call-url gave.
    - **urlCreationDate**, the unix timestamp when the url was created.

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
            "urlCreationDate": 1405517546
        }

    Potential HTTP error responses include:

    - **400 Bad Request:**  The token you passed is not valid or expired.


POST /calls/{token}
-------------------

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
-----------

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

    Server should answer with a status of 200 and the following information in
    its body (json encoded):

    - **apiKey**, the provider public api Key.
    - **callId**, an unique identifier for the call;
    - **progressURL**, the location to reach for websockets;
    - **sessionId**, the provider session identifier;
    - **sessionToken**, the provider session token (for the caller);
    - **websocketToken**, the token to use when authenticating to the websocket.

    Example::

        http POST localhost:5000/v1/calls --verbose\
        calleeId=alexis callType="audio-video"\
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
----------------------------

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
                    "websocketToken": "a2fc1ee029169b62b08a4ba87c328d71"
                }
            ]
        }


    Potential HTTP error responses include:

    - **400 Bad Request:**  The version you passed is not valid.

DELETE /account
---------------

    **Requires authentication**

    Deletes the current account and all data associated to it.

    Example::

        http DELETE localhost:5000/v1/account --verbose\
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

Integration with Firefox Accounts using OAuth
=============================================

A few endpoints are available for integration with Firefox Accounts. This is
the prefered way to login with your Firefox Accounts for loop. For more
information on how to integrate with Firefox Accounts, `have a look at the
Firefox Accounts documentation on MDN
<https://developer.mozilla.org/en-US/Firefox_Accounts#Login_with_the_FxA_OAuth_HTTP_API>`_

POST /fxa-oauth/params
----------------------

    **Requires authentication**

    Provide the client with the parameters needed for the OAuth dance.

    - **client_id**, the client id used by the server;
    - **content_uri**, URI of the content server (to get account information);
    - **oauth_uri**, URI of the OAuth server;
    - **redirect_uri**, URI where the client should redirect once authenticated;
    - **scope**, The scope of the token returned;
    - **state**, A nonce used to check that the session matches.

    ::

        http POST http://localhost:5000/v1/fxa-oauth/params --verbose\
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
--------------------

    **Requires authentication**

    Returns the current status of the hawk session (e.g. if it's authenticated or not)::

        http GET http://localhost:5000/v1/fxa-oauth/token  --verbose\
        --auth-type=hawk --auth='ca13d91d1d4b67edf0b9523a2867b3d1b74eb63823732c441992f813f9da1f76:' --json

    If the current session is authenticated using OAuth, it returns it in the **access_token** attribute.

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
---------------------

    **Requires authentication**

    Trades an OAuth code with an oauth bearer token::

        http POST http://localhost:5000/v1/fxa-oauth/token --verbose\
        state=b56b3753c15efdcae80ea208134ecd6ae97f27027ce9bb11f7c333be6ea7029c\
        code=12345
        --auth-type=hawk --auth='ca13d91d1d4b67edf0b9523a2867b3d1b74eb63823732c441992f813f9da1f76:' --json

    Checks the validity of the given code and state and exchange it with a
    bearer token with the OAuth servers.

    The token is returned in the **access_token** attribute. A few additional
    parameters are returned:

    - **scope** the scope of the token;
    - **token_type** the type of the token returned (here, it will be
      "bearer").

Error Responses
===============

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
- **114 INVALID_OAUTH_STATE**: This come with a 400 and tells the oauth state is invalid;
- **201 BACKEND**: This come with a 503 when a third party is not available at the moment.
