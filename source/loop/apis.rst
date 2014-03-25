====================
Loop Server API v1.0
====================

.. note::

    Unless stated otherwise, all APIs are using application/json for the requests
    and responses content types.

Authentication
==============

Loop server supports authentication with cookie sessions.

APIs
====

**GET** **/**

    Displays version information, for instance::

        {
          "name": "mozilla-loop-server",
          "description": "The Mozilla Loop (WebRTC App) server",
          "version": "0.2.0-DEV",
          "homepage": "https://github.com/mozilla-services/loop-server/",
          "endpoint": "http://loop.services.mozilla.com"
        }  

**POST** **/registration**

    Associates a Simple Push Endpoint (URL) with the authenticated user.

    **can requires authentication (read below)**

    If you aren't authenticated when doing this registration step, then you'll
    be given back a session cookie that you'll need to pass along for the
    other requests.

    Body parameters:

    - **simple_push_url**, the simple push endpoint url as defined in
      https://wiki.mozilla.org/WebAPI/SimplePush#Definitions

    Example::

        POST /registration
        {'simple_push_url': 'https://push.services.mozilla.com/update/MGlYke2SrEmYE8ceyu'}

    Server should aknowledge your request and answer with a status code of
    **200, OK**.

    Potential HTTP error responses include:

    - **400 Bad Request:**  You forgot to pass the simple_push_url, or it's
      not a valid URL.


**POST** **/call-url**

    **Requires authentication**

    Generates a call url for the given `callerId`. This is an URL the caller
    can click on in order to call the caller.

    Body parameters:

    - **callerId**, the caller (the person you will give the link to)
      identifier.

    Response from the server:

    The server should answer this with a 200 status code and a JSON object
    with a "call_url" property.

    Example::

        > POST /call-url
        > data = {'callerId': 'alexis@mozilla.com'}
        < Status 200 OK
        < Body: {"call_url": "http://loop.services.mozilla.com/calls/af123f343" }

    (note that the token had been truncated here for brievity purposes)

    Potential HTTP error responses include:

    - **400 Bad Request:**  You forgot to pass the `callerId`, or it's not
      valid.

**GET**  **/calls/{token}**

    Redirects to the application webapp (for the caller)
    
    - *token* is the token returned by the **POST** on **/call-url**.

    Server should return an "HTTP 302" with the new location.
    Example::

        > GET /calls/af123f343
        < Status 302
        < Location: "http://loop-webapp.services.mozilla.com/#call?token=af123f343" }

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

    Potential HTTP error responses include:

    - **400 Bad Request:**  The token you passed is not valid or expired.

**DELETE** **/calls/{token}**

    **Requires authentication**

    Delete a previously created call url. You need to be the user
    who generated this link in order to delete it.

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
    - **calleeToken**, the provider callee token.

    Example::

        > GET /calls?version=1234
        < Body: {"calls": [{"uuid": "b7aa8022e384b8f5f97160f2c2d52255",
                            "apiKey": "12345",
                            "sessionId": "af32408e"
                            "calleeToken": "e430fd2"},
                           {"apiKey": "67890",
                            "sessionId": "ae3240de"
                            "calleeToken": "f430ff2"}]}

    Potential HTTP error responses include:

    - **400 Bad Request:**  The version you passed is not valid.

**GET** **/calls/id/{uuid}**

    Checks the status of the given call, by looking at its uuid.
    
    Parameters:

        - **uuid** (in the url) is the unique identifier of the
          call.
    
    Server can answer with:

    - "200 OK", meaning that the call exists (but may be not
      answered),
    - "404 Not Found" if the given call doesn't exist or had been
      declined.

**DELETE **/calls/id/{uuid}**

    **Requires authentication**

    Reject a given call. This is to be used by the callee in order
    to reject a call.
    
    Parameters:

        - **uuid** (in the url) is the unique identifier of the
          call.

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
- **405** : unsupported method
- **406** : unacceptable - the client asked for an Accept we don't support
- **503** : service unavailable (provider or database backends may be down)
