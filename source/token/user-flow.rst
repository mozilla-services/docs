=========
User Flow
=========

**Please Note**: BrowserID has been removed from Mozilla Accounts, and
therefore has also been removed from later versions of Tokenserver. Discussion
of BrowserID presented here is for historic purposes only.

Here's the proposed two-step flow (with BrowserID/Mozilla account assertions):

1. the client trades a BrowserID assertion for an :term:`Auth token` and
   corresponding secret
2. the client uses the auth token to sign subsequent requests using
   :term:`Hawk Auth`.


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

- The :term:`Login Server` checks the BrowserID assertion [2] **this step will be
  done locally without calling an external browserid server -- but this could
  potentially happen** (we can use PyBrowserID + use the BID.org certificate)

  The user's email address is extracted, along with any :term:`Generation Number`
  associated with the BrowserID certificate.

- The :term:`Login Server` asks the Users DB for an existing record matching the
  users' email address.

  If so, the allocated :term:`Node` and previously-seen :term:`Generation Number`
  are returned.

- If the submitted :term:`Generation Number` is smaller than the recorded one,
  the :term:`Login Server` returns an error as the client's BrowserID credentials
  are out of date.

  If the submitted :term:`Generation Number` is larger than the recorded one,
  the :term:`Login Server` updates the Users DB with the new value.

- If the user is not allocated to a :term:`Node`, the :term:`Login Server` asks
  for a new one from the :term:`Node Assignment Server` [4]

- The :term:`Login Server` creates a response with an :term:`Auth Token` and
  corresponding :term:`Token Secret` [5] and sends it back to the user.

  The :term:`Auth Token` contains the user id and a timestamp, and is signed
  using the :term:`Signing Secret`. The :term:`Token Secret` is derived from
  the :term:`Master Secret` and :term:`Auth Token` using :term:`HKDF`.

  It also adds the :term:`Node` url in the response under
  *api_endpoint* [6]

  ::

    HTTP/1.1 200 OK
    Content-Type: application/json

    {'id': <token>,
     'secret': <derived-secret>,
     'uid': 12345,
     'api_endpoint': 'https://example.com/app/1.0/users/12345',
    }

- The client saves the node location and hawkauth parameters to use in subsequent
  requests. [6]

- For each subsequent request to the :term:`Service`, the client calculates a
  special Authorization header using :term:`Hawk Auth` [7] and sends
  the request to the allocated node location [8]::

    POST /request HTTP/1.1
    Host: some.node.services.mozilla.com
    Authorization: Hawk id=<auth-token>
                        ts="137131201",   (client timestamp)
                        nonce="7d8f3e4a",
                        mac="bYT5CMsGcbgUdFHObYMEfcx6bsw="

- The node uses the :term:`Signing Secret` to validate the :term:`Auth Token` [9].  If invalid
  or expired then the node returns a 401

- The node calculates the :term:`Token Secret` from its :term:`Master Secret` and the
  :term:`Auth Token`, and checks whether the signature in the Authorization header is
  valid [10]. If it is invalid then the node returns a 401

- The node processes the request as defined by the :term:`Service` [11]

