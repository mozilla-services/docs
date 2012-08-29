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

    The first /1.0/ in the URL defines the version of the Sagrada token.

    Example for Browser-Id::

        GET /1.0/sync/2.0
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
         'api_endpoint': 'https://example.com/app/1.0/users/12345',
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

    > GET /1.0/aitc/1.0
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

    > GET /1.0/aitc/1.0
      Authorization: Browser-ID <assertion>
      X-Conditions-Accepted: True

    < HTTP/1.1 200 OK
      Content-Type: application/json

      { ... token details ... }


Errors
======

All errors are also returned as json responses, following the
structure `described in Cornice
<http://cornice.readthedocs.org/en/latest/validation.html#dealing-with-errors>`_

Status codes and error codes:

- **404** : unknown URL, or unsupported application.
- **400** : malformed request. Possible reasons:

 - missing option
 - bad values
 - malformed json

- **401** : authentication failed or protocol not supported.
  The response in that case will contain WWW-Authenticate headers
  (one per supported scheme)
- **405** : unsupported method
- **406** : unacceptable - the client asked for an Accept we don't support
- **503** : service unavailable (ldap or snode backends may be down)
