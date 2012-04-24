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

    Example::

        HTTP/1.1 200 OK
        Content-Type: application/json

        {'id': <token>,
         'key': <derived-secret>,
         'uid': 12345,
         'api_endpoint': 'https://example.com/app/1.0/users/12345',
        }


All errors are also returned as json responses, following the
structure described in Cornice.

XXX need to document this in Cornice

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
