===============
Server API v1.0
===============

General Description
===================

The only valid HTTP response codes are 200 and 304 since those are part of the
protocol and expected to happen. Anything else, like 400, 403, 404 or 503 must
result in a complete termination of the password exchange. The client can retry
the exchange then at a later time, starting all over with clean state.

Every call must be done with a ''X-KeyExchange-Id'' header, containing a
half-session identifier for the channel. This client ID must be a string of 256
chars. The server will keep track of the two first ids used for a given
channel, from its creation to its deletion and will close the channel and issue
a 400 if any request is made with an unknown id or with no id at all.

Last, if a given IP attempts to flood the server with a lot of calls in a short
time, it will be blacklisted for 10 minutes return 403s in the interim for any
requests made from the same IP. When receiving this error code, legitimate
clients can fall back to a manual transaction. A client that generates a lot of
bad requests will also be blacklisted, but for an hour.


APIS
====

**GET** **https://server/new_channel**

  Returns in the response body a JSON-encoded random channel id of N chars
  from [a-z0-9].

  When the API is called, the id returned is guaranteed to be unique.
  The created channel will have a limited TTL (currently configured to
  5 minutes).

  Return codes:
     - 200: channel created successfully
     - 503: the server was unable to create a new channel.
     - 400: Bad or no client ID. The channel is deleted.
     - 403: the IP is blacklisted.


**GET https://server/channel_id**

  Returns in the response body the content of the channel of id ''channel_id''.
  Returns an ''ETag'' response header containing a unique hash.

  The request can contain a ''If-None-Match'' header containing a hash.
  If the hash is similar to the current hash of the channel, the server
  will return a 304 and an empty body.

  The number of GET calls for a given channel are limited to 6. The channel will
  be deleted by the server after 6 successful GETs.

  Return codes:
     - 200: data retrieved successfully
     - 404: the channel does not exists. It was not created by a call
       to ''new_channel'' or timed out.
     - 304: the data was not changed.
     - 400: Bad or no client ID. The channel is deleted.
     - 403: the IP is blacklisted.


**PUT https://server/channel_id**

  Put in the channel of id ''channel_id'' the content of the request body.
  Returns an ''ETag'' response header containing a unique hash.
  If an If-Match Header is provided, it must be the value of the etag
  before the update to the channel is applied, or \*.
  If different, a precondition failed code is returned.

  If a If-None-Match header is provided and equals to \*, and
  if the channel is not empty (e.g. some data has been already
  put in the channel), a precondition failed code is returned.

  Return codes:
     - 200: data set successfully
     - 404: the channel does not exists. It was not created by a call
       to ''new_channel'' or timed out.
     - 400: Bad or no client ID. The channel is deleted.
     - 403: the IP is blacklisted.
     - 412: a precondition failed.

**POST https://server/report**

  Reports a log to the server, and optionally asks for a channel deletion.

  The log is the body of the request. If the
  request contains a ''X-KeyExchange-Log'' header, its value is prepended
  to the log provided in the body. In other words, the header can be used
  for small logs, and the body for more info. The body size is limited to
  2000 chars. If both body and headers are empty, nothing is logged.

  The current errors reported by the client are described in the next
  section, but the log is a free-form string.

  **Warning**: Under a normal exchange the server is able to count the number
  of calls and close the channel at the end, so this API is not to be used
  to close the channel. Some value should be reported to generate a security
  log. The client is therefore encouraged to always provide a report value
  when calling.

  Optionally, if the request contains the ''X-KeyExchange-Id'' header and a
  ''X-KeyExchange-Cid'' header containing the channel id, the channel will
  be deleted by the server.

  Return codes:
     - 200: logged successfully
     - 403: the IP is blacklisted.
     - 400: bad request (missing log or bad ids)


Error messages
==============


- **jpake.error.timeout** (Timeout) : Reported when the exchange is aborted
  due to timeouts.

- **jpake.error.invalid** (Invalid message): Reported when a malformed message
  is received. A malformed message is one that doesn't correctly parse as JSON.

- **jpake.error.wrongmessage** (Wrong message): Reported when the wrong message
  is received, as identified by the <code>type</code> property in the JSON blob.

- **jpake.error.internal** (Internal J-PAKE failure): Reported when a J-PAKE
  computation step or encryption/decryption step fails.

- **jpake.error.keymismatch** (Key mismatch): Reported when the SHA256 or HMAC
  verification fails, in other words when the PIN wasn't entered correctly and
  both sides ended up with different keys.

- **jpake.error.server** (Unexpected Server Response): Reported when unexpected
  HTTP response from the J-PAKE server is received.

- **jpake.error.userabort (User Abort)** : Reported when a client aborts the
  J-PAKE transaction; for example, when canceling a setup wizard.
