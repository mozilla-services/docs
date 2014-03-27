====================
Loop Server API v1.0
====================

This document is based on the current status of the server. All the examples are
working ones. It doesn't reflect any future implementation and tries to stick
with the currently deployed version.

.. note::

    Unless stated otherwise, all APIs are using application/json for the requests
    and responses content types. Parameters for the GET requests are form
    encoded (?key=value&key2=value2)

To ease testing, you can use `httpie <https://github.com/jkbr/httpie>`_ in
order to make requests. You can find the httpie requests for reference in the
examples.

Authentication
==============

Loop server only supports authentication with cookie sessions as of now.

It may support authentication using FxA assertions in the future, but that's
**not** the case right now.

APIs
====

**GET** **/**

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
            "version": "0.2.0-DEV"
        }


**POST** **/registration**

    Associates a Simple Push Endpoint (URL) with a user, creating a cookie
    session if none is provided.

    **May require authentication**

    If you aren't authenticated when doing this registration step, then you'll
    be given back a session cookie that you'll need to pass along for the
    other requests.

    Body parameters:

    - **simple_push_url**, the simple push endpoint url as defined in
      https://wiki.mozilla.org/WebAPI/SimplePush#Definitions

    Example (when requesting a session cookie)::

        http --session loop POST localhost:5000/registration simple_push_url=https://push.services.mozilla.com/update/MGlYke2SrEmYE8ceyuverbo --verbose

    .. code-block:: http

        POST /registration HTTP/1.1
        Accept: application/json
        Content-Type: application/json; charset=utf-8
        {
            "simple_push_url": "https://push.services.mozilla.com/update/MGlYke2SrEmYE8ceyuverbo"
        }

        HTTP/1.1 200 OK
        Content-Type: application/json; charset=utf-8
        Set-Cookie: loop-session=<session-cookie>; path=/; expires=Tue, 20 Jan 2015 09:18:55 GMT;
        "ok"

    Alternatively, if you set a cookie in the request, with the `Cookie`
    header, you will not be given a cookie in the response (but the push URL
    will be associated with the authenticated user).

    Server should acknowledge your request and answer with a status code of
    **200 OK**.

    Potential HTTP error responses include:

    - **400 Bad Request:**  You forgot to pass the simple_push_url, or it's
      not a valid URL.


**POST** **/call-url**

    **Requires authentication**

    Generates a call url for the given `callerId`. This is an URL the caller
    can click on in order to call the caller.

    Body parameters:

    - **callerId**, the caller (the person you will give the link to)
      identifier. The callerId is supposed to be a valid email address.

    Response from the server:

    The server should answer this with a 200 status code and a JSON object
    with a "call_url" property.

    Example::

        http --session loop POST localhost:5000/call-url callerId=alexis --verbose

    .. code-block:: http

        POST /call-url HTTP/1.1
        Accept: application/json
        Content-Type: application/json; charset=utf-8
        Cookie: loop-session=<session-cookie>
        {
            "callerId": "alexis"
        }

        HTTP/1.1 200 OK
        Content-Type: application/json; charset=utf-8

        {
            "call_url": "http://localhost:5000/calls/FfzMMm2hSl9FqeYUqNO2XuNzJP"
        }

    (note that the token had been truncated here for brievity purposes)

    Potential HTTP error responses include:

    - **400 Bad Request:**  You forgot to pass the `callerId`, or it's not
      valid;
    - **401 Unauthorized**: You need to authenticate to call this URL.

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

**POST /calls/{token}**

    Creates a new incoming call, gets tokens and session from the provider and
    does a simple push notification, then returns caller tokens.

    Server should answer with a status of 200 and the following information in
    its body (json encoded):

    - **uuid**, an unique identifier for the call;
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
            "uuid": "1afeb4340d995938248ce7b3e953fe80"
        }

    (note that return values have been truncated for readability purposes.)

    Potential HTTP error responses include:

    - **400 Bad Request:**  The token you passed is not valid or expired.

**DELETE** **/calls/{token}**

    **Requires authentication**

    Delete a previously created call url. You need to be the user
    who generated this link in order to delete it.

    Example::

        http --session=loop DELETE localhost:5000/calls/FfzMMm2hSl9FqeYUqNO2XuNzJP --verbose

    .. code-block:: http

        DELETE /calls/FfzMMm2hSl9FqeYUqNO2XuNzJP HTTP/1.1
        Accept: application/json
        Cookie: loop-session=<session-cookie>

        HTTP/1.1 204 No Content

    Potential HTTP error responses include:

    - **400 Bad Request:**  The token you passed is not valid or expired.


**GET** **/calls?version=<version>**

    **Requires authentication**

    List incoming calls for the authenticated user since the given version.

    Querystring parameters:

    - **version**, the version simple push gave to the client when waking it
      up. Only calls that happened since this version will be returned.

    Server should answer with a status of 200 and a list of calls in its body. Each call has the following attributes:

    - **uuid**, the unique identifier of the call, which can be used
      to reject a call.
    - **apiKey**, the provider apiKey to use;
    - **sessionId**, the provider session identifier for the callee;
    - **sessionToken**, the provider callee token.

    Example::

        http --session=loop GET localhost:5000/calls\?version=1234 --verbose

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
                    "uuid": "1afeb4340d995938248ce7b3e953fe80"
                },
                {
                    "apiKey": "34159876",
                    "sessionId": "3_XZ40NDcwMDk1Mn5",
                    "sessionToken": "T2==cFGydG5lcl",
                    "uuid": "938248ce7b3e953fe801afeb4340d995"
                }
            ]
        }

    Potential HTTP error responses include:

    - **400 Bad Request:**  The version you passed is not valid.

**GET** **/calls/id/{uuid}**

    Checks the status of the given call, by looking at its uuid.

    Parameters:

        - **uuid** (in the url) is the unique identifier of the
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

**DELETE** **/calls/id/{uuid}**

    **Requires authentication**

    Reject a given call. This is to be used by the callee in order
    to reject a call.

    Parameters:

        - **uuid** (in the url) is the unique identifier of the
          call.

    Example::

        http --session=loop DELETE localhost:5000/calls/id/1afeb4340d995938248ce7b3e953fe80 --verbose

    .. code-block:: http

        DELETE /calls/id/1afeb4340d995938248ce7b3e953fe80 HTTP/1.1
        Accept: application/json
        Cookie: loop-session=<session-cookie>

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
