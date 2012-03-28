=========
User Flow
=========

Here's the proposed two-step flow (with Browser ID):

1. the client trades a browser id assertion for an auth token and corresponding secret
2. the client uses the auth token to sign subsequent requests using two-legged oauth

Getting an :term:`Auth token`:

.. seqdiag::

   seqdiag {
     Client -> "Login Server" [label="request token [1]"];
     "Login Server" -> BID [label="verify [2]"];
     "Login Server" <-- BID;
     "Login Server" -> "User DB" [label="get node [3]"];
     "Login Server" <- "User DB" [label="return node"];
     "Login Server" -> "Node Assignment Server" [label="assign node [4]"];
     "Login Server" <- "Node Assignment Server" [label="return node"];
     "Login Server" -> "Login Server" [label="create response [5]"];
     "Client" <- "Login Server" [label="token [6]"];
   }

Calling the :term:`Service`:

.. seqdiag::

   seqdiag {
     Client -> Client [label="sign request [7]"];
     Client -> "Service Node" [label="perform request [8]"];
     "Service Node" -> "Service Node" [label="verify token and signature [9], [10]"];
     "Service Node" -> "Service Node" [label="process request [11]"];
     Client <- "Service Node" [label="response"];
   }

Detailed steps:

- the client requests a token, giving its browser id assertion [1]::

     GET /1.0/sync/request_token HTTP/1.1
     Host: token.services.mozilla.com
     Authorization: Browser-ID <assertion>

- the :term:`Login Server` checks the browser id assertion [2] **this step will be
  done locally without calling an external browserid server -- but this could
  potentially happen** (we can use pyvep + use the BID.org certificate)

- the :term:`Login Server` asks the Users DB if the user is already allocated to a
  :term:`Node` [3]

- If the user is not allocated to a :term:`Node`, the :term:`Login Server` asks a
  new one to the :term:`Node Assignment Server` [4]

- the :term:`Login Server` creates a response with an :term:`Auth Token` and
  corresponding :term:`Token Secret` [5] and sends it back to the user.

  The :term:`Auth Token` contains the user id and a timestamp, and is signed
  using the :term:`Signing Secret`. The :term:`Token Secret` is derived from
  the :term:`Master Secret` and :term:`Auth Token` using :term:`HKDF`.
  It also adds the :term:`Node` url in the response under
  *service_entry* [6]

  ::

    HTTP/1.1 200 OK
    Content-Type: application/json

    {'oauth_consumer_key': <auth-token>,
        'oauth_consumer_secret': <token-secret>,
        'service_entry': <node>
        }

- the client saves the node location and oauth parameters to use in subsequent
  requests. [6]

- for each subsequent request to the :term:`Service`, the client calculates a special
  Authorization header using two-legged OAuth [7] and sends the request to the
  allocated node location [8]::

     POST /request HTTP/1.1
     Host: some.node.services.mozilla.com
     Authorization: OAuth realm="Example",
                    oauth_consumer_key=<auth-token>
                    oauth_signature_method="HMAC-SHA1",
                    oauth_timestamp="137131201",   (client timestamp)
                    oauth_nonce="7d8f3e4a",
                    oauth_signature="bYT5CMsGcbgUdFHObYMEfcx6bsw%3D"

- the node uses the :term:`Signing Secret` to validate the :term:`Auth Token` [9].  If invalid
  or expired then the node returns a 401
- the node calculates the :term:`Token Secret` from its :term:`Master Secret` and the
  :term:`Auth Token`, and checks whether the signature in the Authorization header is
  valid [10]. If it's an invalid then the node returns a 401
- the node processes the request as defined by the :term:`Service` [11]

