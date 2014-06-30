====================
Loop Server API v1.0
====================

This document is based on the current status of the server. All the examples
had been done with real calls. It doesn't reflect any future implementation and
tries to stick with the currently deployed version.

.. note::

    Unless stated otherwise, all APIs are using application/json for the requests
    and responses content types. Parameters for the GET requests are form
    encoded (?key=value&key2=value2)

To ease testing, you can use `httpie <https://github.com/jkbr/httpie>`_ in
order to make requests. Examples of use with httpie are provided when possible.

Authentication
==============

To deal with authentication, the Loop server uses `Hawk
<https://github.com/hueniverse/hawk>`_ sessions. When you
register, you can do so with different authentications schemes, but you are
always given an hawk session back, that you should use when requesting the
endpoints which need authentication.

Derive hawk credentials from the hawk session token
---------------------------------------------------

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
====

GET /
-----

    Displays version information, for instance::

       http GET localhost:5000 --verbose 

    .. code-block:: http

        GET / HTTP/1.1
        Accept: */*

        HTTP/1.1 200 OK
        Content-Type: application/json; charset=utf-8
        {
            "description": "The Mozilla Loop (WebRTC App) server",
            "endpoint": "http://localhost:5000",
            "homepage": "https://github.com/mozilla/loop-server/",
            "name": "mozilla-loop-server",
            "version": "0.6.0"
            "fakeTokBox": false,
        }


POST /registration
------------------

    Associates a Simple Push Endpoint (URL) with a user.
    Always return an hawk session token in the `Hawk-Session-Token` header.

    **May require authentication**

    You don't *need* to be authenticated to register. In case you don't
    register with a Firefox Accounts assertion or a valid hawk session, you'll
    be given an hawk session token and be connected as an anonymous user.

    You can currently authenticate by sending a valid Firefox Accounts
    assertion or a valid Hawk session.


    Body parameters:

    - **simple_push_url**, the simple push endpoint url as defined in
      https://wiki.mozilla.org/WebAPI/SimplePush#Definitions

    Example (when not authenticated)::

        http POST localhost:5000/registration simple_push_url=https://push.services.mozilla.com/update/MGlYke2SrEmYE8ceyu --verbose

    .. code-block:: http

        POST /registration HTTP/1.1
        Accept: application/json
        Content-Type: application/json; charset=utf-8
        {
            "simple_push_url": "https://push.services.mozilla.com/update/MGlYke2SrEmYE8ceyuverbo"
        }

        HTTP/1.1 200 OK
        Hawk-Session-Token: fab7e901695316eb9d0056a209213985dd2786c8929c8fb922336a530fb30e01

        "ok"

    Server should acknowledge your request and answer with a status code of
    **200 OK**.

    Potential HTTP error responses include:

    - **400 Bad Request:**  You forgot to pass the simple_push_url, or it's
      not a valid URL.

DELETE /registration
--------------------

    **Requires authentication**

    Unregister a given simple push url from the loop server.

    Body parameters:

    - **simple_push_url**, the simple push endpoint url as defined in
      https://wiki.mozilla.org/WebAPI/SimplePush#Definitions

    Example:

    .. code-block:: http

        DELETE /registration HTTP/1.1
        Accept: application/json
        Content-Type: application/json; charset=utf-8
        {
            "simple_push_url": "https://push.services.mozilla.com/update/MGlYke2SrEmYE8ceyuverbo"
        }

        HTTP/1.1 204 No Content

    Server should acknowledge your request and answer with a status code of
    **204 No Content**.

    Potential HTTP error responses include:

    - **400 Bad Request:**  You forgot to pass the simple_push_url, or it's
      not a valid URL.


POST /call-url
--------------

    **Requires authentication**

    Generates a call url for the given `callerId`. This is an URL the caller
    can click on in order to call the caller.

    Body parameters:

    - **callerId**, the caller (the person you will give the link to)
      identifier. The callerId is supposed to be a valid email address.
    - **expiresIn**, the number of hours the call-url will be valid for.
    - **issuer**, The call-url issuer friendly name (optional)

    Response from the server:

    The server should answer this with a 200 status code and a JSON object
    with a "call_url" and an "expiresAt" property, which contains the date when
    the url will expire.

    .. code-block:: http

        POST /call-url HTTP/1.1
        Accept: application/json
        Content-Type: application/json; charset=utf-8
        {
            "callerId": "alexis",
            "expiresIn": 5,
            "issuer": "Manolo Escobar"
        }

        HTTP/1.1 200 OK

        {
            "call_url": "http://localhost:5000/calls/FfzMMm2hSl9FqeYUqNO2XuNzJP",
            "expiresAt": 390135
        }

    (note that the token had been truncated here for brievity purposes)

    Potential HTTP error responses include:

    - **400 Bad Request:**  You forgot to pass the `callerId`, or it's not
      valid;
    - **401 Unauthorized**: You need to authenticate to call this URL.

DELETE /call-url/{token}
------------------------

    **Requires authentication**

    Delete a previously created call url. You need to be the user
    who generated this link in order to delete it.

    .. code-block:: http

        DELETE /call-url/FfzMMm2hSl9FqeYUqNO2XuNzJP HTTP/1.1
        Accept: application/json

        HTTP/1.1 204 No Content

    Potential HTTP error responses include:

    - **400 Bad Request:**  The token you passed is not valid or expired.


**GET**  **/calls/{token}**

    Redirects to the application webapp (for the caller)

    - *token* is the token returned by the **POST** on **/call-url**.

    Server should return an "HTTP 302" with the new location.

    Example::

        http GET localhost:5000/calls/FfzMMm2hSl9FqeYUqNO2XuNzJP --verbose

    .. code-block:: http

        GET /calls/FfzMMm2hSl9FqeYUqNO2XuNzJP HTTP/1.1
        Accept: */* 

        HTTP/1.1 302 Moved Temporarily
        Location: http://localhost:3000/static/#call/FfzMMm2hSl9FqeYUqNO2XuNzJP

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

    - **callId**, an unique identifier for the call;
    - **sessionId**, the provider session identifier;
    - **sessionToken**, the provider session token (for the caller);
    - **apiKey**, the provider public api Key.

    Example::

        http POST localhost:5000/calls/FfzMMm2hSl9FqeYUqNO2XuNzJP --verbose

    .. code-block:: http

        POST /calls/FfzMMm2hSl9FqeYUqNO2XuNzJP HTTP/1.1
        Accept: application/json

        HTTP/1.1 200 OK
        Access-Control-Allow-Methods: GET,POST
        Access-Control-Allow-Origin: http://localhost:3000
        Content-Type: application/json; charset=utf-8

        {
            "apiKey": "44700952",
            "sessionId": "2_MX40NDcwMDk1Mn5-V2VkIE1hciA",
            "sessionToken": "T1==cGFydG5lcl9pZD00NDcwMD",
            "callId": "1afeb4340d995938248ce7b3e953fe80"
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
    - **callType**, Specifies the type of media the remote party intends to
      send. Valid values are "audio" or "audio-video". 

    Server should answer with a status of 200 and the following information in
    its body (json encoded):

    - **callId**, an unique identifier for the call;
    - **sessionId**, the provider session identifier;
    - **sessionToken**, the provider session token (for the caller);
    - **apiKey**, the provider public api Key.

    Example:

    .. code-block:: http

        POST /calls HTTP/1.1
        Accept: application/json
        Content-Type: application/json; charset=utf-8
        {
            "calleeId": ["alexis@mozilla.com", "+34123456789"],
        }

        HTTP/1.1 200 OK

        {
            "apiKey": "44700952",
            "sessionId": "2_MX40NDcwMDk1Mn5-V2VkIE1hciA",
            "sessionToken": "T1==cGFydG5lcl9pZD00NDcwMD",
            "callId": "1afeb4340d995938248ce7b3e953fe80"
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

    - **callId**, the unique identifier of the call, which can be used
      to reject a call.
    - **callerId**, the friendly name of the user that initiated the call;
    - **apiKey**, the provider apiKey to use;
    - **sessionId**, the provider session identifier for the callee;
    - **sessionToken**, the provider callee token.

    .. code-block:: http

        GET /calls?version=1234 HTTP/1.1
        Accept: application/json
        Cookie: loop-session=<session-cookie>

        HTTP/1.1 200 OK
        Content-Type: application/json; charset=utf-8

        {
            "calls": [
                {
                    "apiKey": "13245678",
                    "sessionId": "2_MX40NDcwMDk1Mn5",
                    "sessionToken": "T1==cGFydG5lcl",
                    "callId": "1afeb4340d995938248ce7b3e953fe80"
                    "callerId": "Manolo Escobar"
                },
                {
                    "apiKey": "34159876",
                    "sessionId": "3_XZ40NDcwMDk1Mn5",
                    "sessionToken": "T2==cFGydG5lcl",
                    "callId": "938248ce7b3e953fe801afeb4340d995"
                    "callerId": "El fari"
                }
            ]
        }

    Potential HTTP error responses include:

    - **400 Bad Request:**  The version you passed is not valid.

GET /calls/id/{callId}
----------------------

    Checks the status of the given call, by looking at its callId.

    Parameters:

        - **callId** (in the url) is the unique identifier of the
          call.

    Example::

        http GET localhost:5000/calls/id/1afeb4340d995938248ce7b3e953fe80 --verbose

    .. code-block:: http

        GET /calls/id/1afeb4340d995938248ce7b3e953fe80 HTTP/1.1
        Accept: application/json

        HTTP/1.1 200 OK
        Content-Type: application/json; charset=utf-8

        "ok"

    Server can answer with:

    - "200 OK", meaning that the call exists (but may be not
      answered),
    - "404 Not Found" if the given call doesn't exist or had been
      declined.

DELETE /calls/id/{callId}
-------------------------

    Rejects a given call. This is to be used by the callee in order
    to reject a call, or by the caller in order to hang-up.

    Parameters:

        - **callId** (in the url) is the unique identifier of the
          call.

    Example::

        http DELETE localhost:5000/calls/id/1afeb4340d995938248ce7b3e953fe80 --verbose

    .. code-block:: http

        DELETE /calls/id/1afeb4340d995938248ce7b3e953fe80 HTTP/1.1
        Accept: application/json

        HTTP/1.1 204 No Content

    Server can answer with:

    - "204 No Content", meaning that the call had been rejected
      successfully.
    - "404 Not Found" if the given call doesn't exist (that can be
      the case if the call had already been rejected).

Error Responses
===============

All errors are also returned, wherever possible, as json responses following the
structure `described in Cornice
<http://cornice.readthedocs.org/en/latest/validation.html#dealing-with-errors>`_.

In cases where generating such a response is not possible (e.g. when a request
if so malformed as to be unparsable) then the resulting error response will
have a *Content-Type* that is not **application/json**.

The top-level JSON object in the response will always contain a key named
`status`, which maps to a string identifying the cause of the error.  Unexpected
errors will have a `status` string of "error"; errors expected as part of
the protocol flow will have a specific `status` string as detailed below.

Error status codes and their corresponding output are:

- **404** : unknown URL, or unsupported application.
- **400** : malformed request. Possible causes include a missing
  option, bad values or malformed json.
- **401** : you need to be authenticated
- **403** : you are authenticated but don't have access to the resource you are
            requesting.
- **405** : unsupported method
- **406** : unacceptable - the client asked for an Accept we don't support
- **503** : service unavailable (provider or database backends may be down)
