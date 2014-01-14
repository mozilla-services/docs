=====================
Token Server API v1.0
=====================

.. note::

    Unless stated otherwise, all APIs are using application/json for the requests
    and responses content types.


**GET** **/1.0/<app_name>/<app_version>**

    Asks for new token given some credentials in the Authorization header.

    By default, the authentication scheme is Browser ID but other schemes can
    potentially be used if supported by the login server.

    - **app_name** is the name of the application to access, like **sync**.
    - **app_version** is the specific version number of the api that you want
      to access.

    The first /1.0/ in the URL defines the version of the authentication
    token itself.

    Example for Browser-Id::

        GET /1.0/sync/1.5
        Host: token.services.mozilla.com
        Authorization: Browser-ID <assertion>

    This API returns several values in a json mapping:

    - **id** -- a signed authorization token, containing the
      user's id for the application and the node.
    - **key** -- a secret derived from the shared secret
    - **uid** -- the user id for this service
    - **api_endpoint** -- the root URL for the user for the service.
    - **duration** -- the validity duration of the issued token

    Example::

        HTTP/1.1 200 OK
        Content-Type: application/json

        {'id': <token>,
         'key': <derived-secret>,
         'uid': 12345,
         'api_endpoint': 'https://db42.sync.services.mozilla.com/1.5/12345',
         'duration': 300,
        }


Conditions to use the service
=============================

If the service needs the user to accept some terms of service, privacy policy,
etc, the client needs to send a special flag saying that these terms of
service had been effectively signed. Here is the intended client/server flow:

On the first call, the URLs that the user has to agree on are not known by the
client.  The server will answer with a HTTP 403 "Need
to accept conditions" containing a json dict with the conditions that need to
be accepted. This can be something like::

    > GET /1.0/sync/1.5
      Authorization: Browser-ID <assertion>

    < 403 Forbidden
      Content-Type: application/json

      { 'status': 'error',
         'errors': [{'location': 'header',
                     'name': 'X-Conditions-Accepted',
                     'description': 'Need to Accept conditions'},
                     'condition_urls': {'tos': 'http://url-to-tos'}],
      }

On the next call, the client needs to include the 'X-Conditions-Accepted' HTTP
header to indicate acceptance of the terms::

    > GET /1.0/sync/1.5
      Authorization: Browser-ID <assertion>
      X-Conditions-Accepted: True

    < HTTP/1.1 200 OK
      Content-Type: application/json

      { ... token details ... }


Response Headers
================

**Retry-After**

    When sent together with an HTTP 503 status code, this header signifies that
    the server is undergoing maintenance. The client should not attempt any
    further requests to the server for the number of seconds specified in
    the header value.

**X-Backoff**

    This header may be sent to indicate that the server is under heavy load
    but is still capable of servicing requests.  Unlike the **Retry-After**
    header, **X-Backoff** may be included with any type of response, including
    a **200 OK**.

    Clients should avoid unnecessary requests to the server for the number of seconds
    specified in the header value.  For example, clients may avoid pre-emptively
    refreshing token if an X-Backoff header was recently seen.

**X-Timestamp**

    This header will be included with all "200" and "401" responses, giving
    the current POSIX timestamp as seen by the server, in seconds.  It may
    be useful for client to adjust their local clock when generating BrowserID
    assertions.


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
- **401** : authentication failed or protocol not supported.
  The response in that case will contain WWW-Authenticate headers
  (one per supported scheme) and may report the following `status`
  strings:

    - **"invalid-credentials"**: authentication failed due to invalid
      credentials e.g. a bad signature on the BrowserID assertion.
    - **"invalid-timestamp"**: authentication failed because the included
      timestamp differed too greatly from the server's current time.
    - **"invalid-generation"**:  authentication failed because the server
      has seen credentials with a more recent generation number.

- **403** : authentication refused despite valid credentials.  The response
  may report the following `status` strings:

    - **"conditions-reqiured"**: the X-Conditions-Accepted header must
      be provided in order to use the requested server.

- **405** : unsupported method
- **406** : unacceptable - the client asked for an Accept we don't support
- **503** : service unavailable (ldap or snode backends may be down)
