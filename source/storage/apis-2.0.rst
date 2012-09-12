.. _server_syncstorage_api_20:

====================
SyncStorage API v2.0
====================

The SyncStorage API defines a HTTP web service used to store and retrieve
simple objects called **Basic Storage Objects** (**BSOs**), which are organized
into named **collections**.


Status: FINAL DRAFT
===================

This document is currently in **final draft** status.  While no substantial
modifications are expected, there may be small changes and clarifications
as implementation progresses.


Concepts
========

.. _syncstorage_wbo:

Basic Storage Object
--------------------

A **Basic Storage Object (BSO)** is the generic JSON wrapper around all
items passed into and out of the SyncStorage server. Like all JSON documents,
BSOs are composed of unicode character data rather than raw bytes and must
be encoded for transmission over the network.  The SyncStorage service always
encodes BSOs in UTF-8.

Basic Storage Objects have the following fields:


+---------------+-----------+------------+---------------------------------------------------------------+
| Parameter     | Default   | Type/Max   |  Description                                                  |
+===============+===========+============+===============================================================+
| id            | required  |  string,   | An identifying string. For a user, the id must be unique for  |
|               |           |  64        | a BSO within a collection, though objects in different        |
|               |           |            | collections may have the same ID.                             |
|               |           |            |                                                               |
|               |           |            | BSO ids may only contain characters from the urlsafe-base64   |
|               |           |            | alphabet (i.e. alphanumerics, underscore and hyphen)          |
+---------------+-----------+------------+---------------------------------------------------------------+
| version       | none      | integer,   | The version number at which this object was last modified.    |
|               |           | positive,  | This is a server-assigned integer that is set automatically   |
|               |           | 16 digits  | on each write; any client-supplied value for this field is    |
|               |           |            | ignored.                                                      |
+---------------+-----------+------------+---------------------------------------------------------------+
| timestamp     | none      | integer,   | The timestamp at which this object was last modified, in      |
|               |           | positive,  | milliseconds since UNIX epoch (1970-01-01 00:00:00 UTC).      |
|               |           | 16 digits  | This is set automatically by the server according to its own  |
|               |           |            | clock; any client-supplied value for this field is ignored.   |
+---------------+-----------+------------+---------------------------------------------------------------+
| payload       | empty     | string,    | A string containing the data of the record. The structure of  |
|               | string    | 256k       | this string is defined separately for each BSO type. This     |
|               |           |            | spec makes no requirements for its format. In practice,       |
|               |           |            | JSONObjects are common.                                       |
+---------------+-----------+------------+---------------------------------------------------------------+
| sortindex     | none      | integer,   | An integer indicating the relative importance of this item in |
|               |           | positive,  | the collection.                                               |
|               |           | 9 digits   |                                                               |
+---------------+-----------+------------+---------------------------------------------------------------+
| ttl           | none      | integer,   | The number of seconds to keep this record. After that time    |
|               |           | positive,  | this item will no longer be returned in response to any       |
|               |           | 9 digits   | request, and it may be pruned from the database.  If not      |
|               |           |            | specified or null, the record will not expire.                |
+---------------+-----------+------------+---------------------------------------------------------------+


Example::

    {
      "id": "-F_Szdjg3GzY",
      "version": 174268,
      "timestamp": 1349058303600,
      "sortindex": 140,
      "payload": "THIS IS AN EXAMPLE"
    }


Collections
-----------

Each BSO is assigned to a collection with other related BSOs. Collection names
may only contain characters from the urlsafe-base64 alphabet (i.e. alphanumeric
characters, underscore and hyphen).

Collections are created implicitly when a BSO is stored in them for the first
time.  They continue to exist until they are explicitly deleted, even if they
no longer contain any BSOs.


Version Numbers
---------------

In order to allow multiple clients to coordinate their changes, the SyncStorage
server associates a **version number** with the data stored for each user.
This is a server-assigned integer value that increases with every modification
made to the user's data.

The version number is tracked at three levels of nesting:

    * The **current version number** is increased whenever any change is made
      to the user's data.  It applies to the store as a whole.
    * Each collection has a **last-modified version** giving the version
      number at which that collection was last modified.  It will always
      be less than or equal to the current version number.
    * Each BSO has a **last-modified version** giving the version number
      at which that item was last modified.  It will always be less than
      or equal to the last-modified version of the containing collection.

The version number is guaranteed to be monotonically increasing and can be
used for coordination and conflict management as described in
:ref:`syncstorage_concurrency`.  It is **not** guaranteed to increment
sequentially, and clients should treat it as an opaque integer value.

As a special case, resources that do not exist are considered to have a
last-modified version number of zero.


API Access and Discovery
========================


The SyncStorage data for a given user may be accessed via authenticated
HTTP requests to their SyncStorage API endpoint.  All requests will be
to URLs of the form::

    https://<endpoint-url>/<api-instruction>

The user's SyncStorage endpoint URL can be obtained via the Sagrada Discovery
and Authentication workflow [1]_.  All requests must be signed using MAC
Access Authentication credentials [2]_.

Request and response bodies are all JSON-encoded unless otherwise specified.

Error responses generated by the SyncStorage server will, wherever possible,
follow the JSON error format described in :ref:`syncstorage_error_format`.
The format of a successful response is defined in the appropriate section
of the API Instructions documentation.

.. [1] https://wiki.mozilla.org/Services/Sagrada/ServiceClientFlow
.. [2] https://wiki.mozilla.org/Services/Sagrada/ServiceClientFlow#Access


API Instructions
================

General Info
------------

APIs in this section provide a facility for obtaining general info for the
authenticated user.

**GET** **https://<endpoint-url>/info/collections**

    Returns an object mapping collection names associated with the account to
    the last-modified version number for each collection.

    Possible HTTP status codes:

    - **304 Not Modified:**  the current version number is less than or equal
      to the value specified in the *X-If-Modified-Since-Version* header.


**GET** **https://<endpoint-url>/info/quota**

    Returns an object giving details of the user's current usage and
    quota.  It will have the following keys:

    - **usage**:  the user's total current usage in bytes.
    - **quota**:  the user's total quota in bytes
                  (or null if quotas are not in use)

    Note that usage numbers may be approximate.

    Possible HTTP status codes:

    - **304 Not Modified:**  the current version number is less than or equal
      to the value specified in the *X-If-Modified-Since-Version* header.


**GET** **https://<endpoint-url>/info/collection_usage**

    Returns an object mapping collection names associated with the account to
    the data volume used for each collection (in bytes).

    Note that this request may be very expensive as it calculates more
    detailed and accurate usage information than the request to
    **/info/quota**.

    Possible HTTP status codes:

    - **304 Not Modified:**  the current version number is less than or equal
      to the value specified in the *X-If-Modified-Since-Version* header.


**GET** **https://<endpoint-url>/info/collection_counts**

    Returns an object mapping collection names associated with the account to
    the total number of items in each collection.

    Possible HTTP status codes:

    - **304 Not Modified:**  the current version number is less than or equal
      to the value specified in the *X-If-Modified-Since-Version* header.


Individual Collection Interaction
---------------------------------

APIs in this section provide a mechanism for interacting with a single
collection.

**GET** **https://<endpoint-url>/storage/<collection>**

    Returns a list of the BSOs contained in a collection.  For example::

        {
         "items": ["GXS58IDC_12", "GXS58IDC_13", "GXS58IDC_15"]
        }

    By default only the BSO ids are returned, but full objects can be requested
    using the **full** parameter.

    This request has additional optional parameters:

    - **ids**: a comma-separated list of ids. Only objects whose id is in this
      list will be returned.  A maximum of 100 ids may be provided.

    - **older**: a version number. Only objects whose last-modified version
      number is strictly smaller than this value will be returned.

    - **newer**: a version number. Only objects whose last-modified version
      number is strictly greater than this value will be returned.

    - **full**: any value.  If provided then the response will be a list of
      full BSO objects rather than a list of ids.

    - **limit**: a positive integer. At most that many objects will be.
      returned. If more than that many objects matched the query, an
      *X-Next-Offset* header will be returned.

    - **offset**: a string, as returned in the *X-Next-Offset* header of
      a previous request using the **limit** parameter.

    - **sort**: sorts the output:
       - 'oldest' - orders by last-modified version number, smallest first
       - 'newest' - orders by last-modified version number, largest first
       - 'index' - orders by the sortindex, highest weight first

    The response will include an *X-Num-Records* header indicating the
    total number of records to expect in the body.

    If the request included a **limit** parameter and there were more than
    that many items matching the query, the response will include an
    *X-Next-Offset* header.  This value can be passed back to the server in
    the **offset** parameter to efficiently skip over the items that have
    already been read.  See :ref:`syncstorage_paging` for an example.

    Two output formats are available for multiple record GET requests.
    They are triggered by the presence of the appropriate format in the
    *Accept* request header and are prioritized in the order listed below:

    - **application/json**: the output is a JSON object with the key "items"
      mapping to a list of the requested records, as either string ids or full
      JSON objects.
    - **application/newlines**: the output contains each record on a separate
      line, as either a string id or a full JSON object.

    Possible HTTP status codes:

    - **304 Not Modified:**  the last-modified version number of
      the collection is less than or equal to the value in the
      *X-If-Modified-Since-Version* header.
    - **400 Bad Request:**  too many ids where included in the query parameter.
    - **404 Not Found:**  the user has no such collection.
    - **412 Precondition Failed:**  the last-modified version number of
      the collection is greater than the value in the
      *X-If-Unmodified-Since-Version* header.


**GET** **https://<endpoint-url>/storage/<collection>/<id>**

    Returns the BSO in the collection corresponding to the requested id

    Possible HTTP error responses:

    - **304 Not Modified:**  the last-modified version number of
      the item is less than or equal to the value in the
      *X-If-Modified-Since-Version* header.
    - **404 Not Found:**  the user has no such collection, or it contains
      no such object.
    - **412 Precondition Failed:**  the last-modified version number of
      the item is greater than the value in the
      *X-If-Unmodified-Since-Version* header.


**PUT** **https://<endpoint-url>/storage/<collection>/<id>**

    Creates or overwrites a specific BSO within a collection.

    The request body must contain full JSON data for the BSO.  It will be
    written into the specified collection under the specified id.

    This request may include the *X-If-Unmodified-Since-Version* header to
    avoid overwriting the data if it has been changed since the client
    fetched it.

    Successful requests will receive a **201 Created** response if a new
    BSO is created, or a **204 No Content** response if an existing BSO
    is overwritten.  The response will include an *X-Last-Modified-Version*
    header giving the new current version number, which is also the new
    last-modified version number for the containing collection.

    Note that the server may impose a limit on the amount of data submitted
    for storage in a single BSO.

    Possible HTTP error responses:

    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.
    - **412 Precondition Failed:**  the last-modified version number of
      the item is greater than the value in the
      *X-If-Unmodified-Since-Version* header.
    - **413 Request Entity Too Large:**  the object is larger than the
      server is willing to store.
    - **415 Unsupported Media Type:**  the request had a Content-Type other
      than **application/json**.


**POST** **https://<endpoint-url>/storage/<collection>/<id>**

    Creates or updates a specific BSO within a collection.
    The request body must be a JSON object giving new data for the BSO.

    If the target BSO already exists then it will be updated with the data
    from the request body.  Fields that are not provided in the request body
    will not be overwritten, so it is possible to e.g. update the `ttl` field
    of a BSO without re-submitting its `payload`.  Fields that are explicitly
    set to `null` in the request body will be set to their default value
    by the server.

    If the target BSO does not exist, then fields that are not provided in
    the request body will be set to their default value by the server.

    This request may include the *X-If-Unmodified-Since-Version* header to
    avoid overwriting the data if it has been changed since the client
    fetched it.

    Successful requests will receive a **201 Created** response if a new
    BSO is created, or a **204 No Content** response if an existing BSO
    is updated.  The response will include an *X-Last-Modified-Version* header
    giving the new current version number, which is also the new last-modified
    version number for the containing collection.

    Note that the server may impose a limit on the amount of data submitted
    for storage in a single BSO.

    Possible HTTP error responses:

    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.
    - **412 Precondition Failed:**  the last-modified version number of
      the item is greater than the value in the
      *X-If-Unmodified-Since-Version* header.
    - **413 Request Entity Too Large:**  the object is larger than the
      server is willing to store.
    - **415 Unsupported Media Type:**  the request had a Content-Type other
      than **application/json**.


**POST** **https://<endpoint-url>/storage/<collection>**

    Takes a list of BSOs in the request body and iterates over them,
    effectively doing a series of individual POSTs with the same updated
    version number.

    Each BSO record in the request body must include an "id" field, and the
    corresponding BSO will be created or updated according to the semantics
    of a **POST** request targeting that specific record.  In particular,
    this means that fields not provided in the request body will not be
    overwritten on BSOs that already exist.

    This request returns an object with details of success or failure for each
    each BSO.  It will have the following keys:

    - **success:** a list of ids of BSOs that were successfully stored.
    - **failed:** an object whose keys are the ids of BSOs that were not
      stored successfully, and whose values are lists of strings
      describing possible reasons for the failure.

    For example::

        {
         "success": ["GXS58IDC_12", "GXS58IDC_13", "GXS58IDC_15",
                     "GXS58IDC_16", "GXS58IDC_18", "GXS58IDC_19"],
         "failed": {"GXS58IDC_11": ["invalid version"],
                    "GXS58IDC_14": ["invalid version"]}
        }

    Posted BSOs whose ids do not appear in either "success" or "failed"
    should be treated as having failed for an unspecified reason.

    Two input formats are available for multiple record POST requests,
    selected by the *Content-Type* header of the request:

    - **application/json**: the input is a JSON list of objects, one for
      for each BSO in the request.

    - **application/newlines**: each BSO is sent as a separate JSON object
      on its own line.

    Note that the server may impose a limit on the total amount of data
    included in the request, and/or may decline to process more than a certain
    number of BSOs in a single request.

    Possible HTTP error responses:

    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.
    - **412 Precondition Failed:**  the last-modified version number of
      the collection is greater than the value in the
      *X-If-Unmodified-Since-Version* header.
    - **413 Request Entity Too Large:**  the request contains more data than the
      server is willing to process in a single batch.
    - **415 Unsupported Media Type:**  the request had a Content-Type other
      than **application/json** or **application/newlines**.


**DELETE** **https://<endpoint-url>/storage/<collection>**

    Deletes an entire collection.
    Successful requests will receive a **204 No Content** response.

    After executing this request, the collection will not appear 
    in the output of **GET /info/collections** and calls to
    **GET /storage/<collection>** will generate a **404 Not Found**
    response.

    Possible HTTP error responses:

    - **404 Not Found:**  the user has no such collection.
    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.
    - **412 Precondition Failed:**  the last-modified version number of
      the collection is greater than the value in the
      *X-If-Unmodified-Since-Version* header.


**DELETE** **https://<endpoint-url>/storage/<collection>?ids=<ids>**

    Deletes multiple BSOs from a collection with a single request.
    Successful requests will receive a **204 No Content** response.

    This request takes a parameter to select which items to delete:

    - **ids**: deletes BSO from the collection whose ids that are in
      the provided comma-separated list.  A maximum of 100 ids may be
      provided.

    The collection itself will still exist on the server after executing
    this request.  Even if all the BSOs in the collection are deleted, it
    will receive an updated last-modified version number, appear in the output
    of **GET /info/collections**, and be readable via
    **GET /storage/<collection>**

    Possible HTTP error responses:

    - **400 Bad Request:**  too many ids where included in the query parameter.
    - **404 Not Found:**  the user has no such collection.
    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.
    - **412 Precondition Failed:**  the last-modified version number of
      the collection is greater than the value in the
      *X-If-Unmodified-Since-Version* header.


**DELETE** **https://<endpoint-url>/storage/<collection>/<id>**

    Deletes the BSO at the given location.
    Successful requests will receive a **204 No Content** response.

    Possible HTTP error responses:

    - **404 Not Found:**  the user has no such collection, or it contains
      no such object.
    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.
    - **412 Precondition Failed:**  the last-modified version number of
      the item is greater than the value in the
      *X-If-Unmodified-Since-Version* header.


Multi-Collection Interaction
----------------------------

APIs in this section are used for interaction with multiple collections.

**DELETE** **https://<endpoint-url>/storage**

    Deletes all records for the user.
    Successful requests will receive a **204 No Content** response.

    Possible HTTP error responses:

    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.


Request Headers
===============

**X-If-Modified-Since-Version**

    This header may be added to any GET request, set to a version number. If
    the last-modified version of the target resource is less than or equal
    to the version number given, then a **304 Not Modified** response will
    be returned and re-transmission of the unchanged data will be avoided.

    It is similar to the standard HTTP **If-Modified-Since** header, but the
    value is an opaque version number rather than a timestamp.

    If the value of this header is not a valid positive integer, or if the
    **X-If-Unmodified-Since-Version** header is also present, then a
    **400 Bad Request** response will be returned.


**X-If-Unmodified-Since-Version**

    This header may be added to any request to a collection or item, set to a
    version number.  If the last-modified version of the target resource is
    greater than the version number given, the request will fail with a
    **412 Precondition Failed** response.

    It is similar to the standard HTTP **If-Unmodified-Since** header, but the
    value is an opaque version number rather than a timestamp.

    If the value of this header is not a valid positive integer, or if the
    **X-If-Modified-Since-Version** header is also present, then a
    **400 Bad Request** response will be returned.


Response Headers
================

**Retry-After**

    When sent together with an HTTP 503 status code, this header signifies that
    the server is undergoing maintenance. The client should not attempt any
    further requests to the server for the number of seconds specified in
    the header value.

    When sent together with a HTTP 409 status code, this header gives the time
    after which the conflicting edits are expected to complete.  Clients should
    wait until at least this time before retrying the request.

**X-Backoff**

    This header may be sent to indicate that the server is under heavy load
    but is still capable of servicing requests.  Unlike the **Retry-After**
    header, **X-Backoff** may be included with any type of response, including
    a **200 OK**.

    Clients should perform the minimum number of additional requests required
    to maintain consistency of their stored data, then not attempt any further
    requests for the number of seconds specified in the header value.

**X-Last-Modified-Version**

    This header gives the last-modified version number of the target resource
    as seen during processing of the request, and will be included in all
    success responses (200, 201, 204).  When given in response to a write
    request, this will be equal to the new current version number and the
    new last-modified version number of any BSOs created or changed by the
    request.

    It is similar to the standard HTTP **Last-Modified** header, but the value
    is an opaque version number rather than a timestamp.

**X-Timestamp**

    This header will be sent back with all responses, indicating the current
    timestamp on the server.  When given in response to a write request, this
    will be equal to the new timestamp value of any BSOs created or changed
    by that request.

    It is similar to the standard HTTP **Date** header, but the value is
    expressed in integer milliseconds for extra precision.

**X-Num-Records**

    This header may be sent back with multi-record responses, to indicate the
    total number of records included in the response.

**X-Next-Offset**

    This header may be sent back with multi-record responses where the request
    included a **limit** parameter.  Its presence indicates that the number of
    available records exceeded the given limit.  The value from this header
    can be passed back in the **offset** parameter to retrieve additional
    records.

    The value of this header will always be a string of characters from the
    urlsafe-base64 alphabet.  The specific contents of the string are an
    implementation detail of the server, so clients should treat it as an
    opaque token.

**X-Quota-Remaining**

    This header may be returned in response to write requests, indicating
    the amount of storage space remaining for the user in bytes.  It will
    not be returned if quotas are not enabled on the server.


HTTP status codes
=================

Since the syncstorage protocol is implemented on top of HTTP, clients should be
prepared to deal gracefully with any valid HTTP response.  This section serves
to highlight the response codes that explicitly form part of the syncstorage
protocol.

**200 OK**

    The request was processed successfully, and the server is returning
    useful information in the response body.


**201 Created**

    The request was processed successfully and resulted in the creation of
    a new BSO.  No entity body is returned.


**204 Not Content**

    The request was processed successfully, and the server has no useful
    data to return in the response body.


**304 Not Modified**

    For requests that include the *X-If-Modified-Since-Version* header, this
    response code indicates that the resource has not been modified.  The
    client should continue to use its local copy of the data.


**400 Bad Request**

    The request itself or the data supplied along with the request is invalid
    and could not be processed by the server.  For example, this response will
    be returned if a header value is incorrectly formatted or if a JSON request
    body cannot be parsed.

    The response will have a *Content-Type* of **application/json** and the
    body will follow the format described in :ref:`syncstorage_error_format`
    to give a description of the error.


**401 Unauthorized**

    The authentication credentials are invalid on this node. This may be caused
    by a node reassignment or by an expired/invalid auth token. The client
    should check with the auth server whether the user's node has changed. If
    it has changed, the current sync is to be aborted and should be retried
    against the new node.


**403 Forbidden**

    The server refused to fulfill the request, for reasons other than invalid
    user credentials.

    This response may be used to refuse service to clients with known problems
    or incompatibilities.  The JSON error response in this case will have a
    `status` field of "upgrade-required".  Clients should inform the user of
    the failure and refrain from making further requests.


**404 Not Found**

    The requested resource could not be found. This may be returned for **GET**
    and **DELETE** requests, for non-existent records and empty collections.


**405 Method Not Allowed**

    The request URL does not support the specific request method.  For example,
    attempting a PUT request to /info/quota would produce a 405 response.


**409 Conflict**

    The write request (PUT, POST, DELETE) has been rejected due conflicting
    changes made by another client, either to the target resource itself or
    to a related resource.  The server cannot currently complete the request
    without risking data loss.

    The client should retry the request after accounting for any changes
    introduced by other clients.

    This response will include a *Retry-After* header indicating the time at
    which the conflicting edits are expected to complete.  Clients should
    wait until at least this time before retrying the request.


**412 Precondition Failed**

    For requests that included the *X-If-Unmodified-Since-Version* header, this
    response code indicates that the resource has in fact been modified by a
    more recent version.  The requested write operation will not have been
    performed.


**413 Request Entity Too Large**

    The body submitted with a write request (PUT, POST) was larger than the
    server is willing to accept.  For multi-record POST requests, the client
    should retry by sending the records in smaller batches.


**415 Unsupported Media Type**

    The Content-Type header submitted with a write request (PUT, POST)
    specified a data format that is not supported by the server.


**503 Service Unavailable**

    Indicates that the server is undergoing maintenance.  Such a response will
    include a  *Retry-After* header, and the client should not attempt
    another sync for the number of seconds specified in the header value.
    The response body may contain a JSON string describing the server's status
    or error.


.. _syncstorage_error_format:

Error Response Format
=====================

Error responses generated by the SyncStorage server will, wherever possible,
use the Cornice error description format [3]_ to give details of the error.
Such responses will have a *Content-Type* of **application/json** and the
body will be a JSON object with structure as detailed below.

In cases where generating such a response is not possible (e.g. when a request
if so malformed as to be unparsable) then the resulting error response will
have a *Content-Type* that is not **application/json**.

The top-level JSON object in the response will always contain a key named
`status`, which will map to one of the following strings to identify the
cause of the error:

  * **error**:  a generic unexpected error, such as malformed input data.
  * **upgrade-required**:  the server refused the request due to known bugs
    or incompatibilities in the client.

The response may optionally include a key named `errors`, which will map
to a list of JSON objects describing particular errors found in the request.
Each individual error description object will in turn have the following
key-value pairs:

  * **location**:  a string giving the location of the offending component
    of the request; one of "querystring", "header" or "body".
  * **name**:  a string giving the name of the offending component of the
    request; for example the name of a specific header.
  * **reason**:  a string identifying the cause of the error; one of
    "missing", "invalid" or "unexpected".
  * **description**:  a string giving a human-readable description of the
    error; this is for informational purposes only and the precise contents
    of this string are undefined.

As a concrete example, a request with a non-integer value for the
*X-If-Modified-Since* header would result in the following error response::

    HTTP/1.1 400 Bad Request
    Content-Type: application/json

    { 'status': 'error',
      'errors': [{'location': 'header',
                  'name': 'X-If-Modified-Since',
                  'reason': 'invalid',
                  'description': 'value is not an integer'}]}

A request from a user-agent that is known to be buggy might be refused service
with the following error response::

    HTTP/1.1 403 Forbidden
    Content-Type: application/json

    { 'status': 'upgrade-required',
      'errors': [{'location': 'header',
                  'name': 'User-Agent',
                  'reason': 'invalid',
                  'description': 'That client is buggy, please upgrade.'}]}

If the server wished to refuse service without giving a detailed reason, then
the error response would be::

    HTTP/1.1 403 Forbidden
    Content-Type: application/json

    { 'status': 'upgrade-required' }


.. [3] http://cornice.readthedocs.org/en/latest/validation.html#dealing-with-errors

.. _syncstorage_concurrency:

Concurrency and Conflict Management
===================================

The SyncStorage service allows multiple clients to synchronize data via
a shared server without requiring inter-client coordination or blocking.
To achieve proper synchronization without skipping or overwriting data,
clients are expected to use version-number-driven coordination features such
as **X-Last-Modified-Version** and **X-If-Unmodified-Since-Version**.

The server guarantees a strictly consistent and monotonically-increasing
version number across the user's stored data.  Any request that alters the
contents of a collection will cause the current version number to increase,
and will update the last-modified version for that collection to match it.
Any BSOs added or modified by such a request will have their "version" field
set to the updated version number.

Conceptually, each write request will perform the following operations as
an atomic unit:

  * Allocate a new version number, larger than the current version number
    of the user's stored data.  Call this version number `V`.
  * Create any new BSOs as specified by the request, setting their "version"
    field to `V` and their "timestamp" field to the current time.
  * Modify any existing BSOs as specified by the request, setting their
    "version" field to `V` and their "timestamp" field to the current time.
  * Delete any BSOs as specified by the request.
  * Set the last-modified version for the collection to `V`.
  * Set the current version number for the user's data to `V`.
  * Generate a **201** or **204** response with the **X-Last-Modified-Version**
    header set to `V`.

While write requests from different clients may be processed concurrently
by the server, they will appear to the clients to have occurred sequentially,
instantaneously and atomically according to the above sequence.

To avoid having the server transmit data that has not changed since the last
request, clients should set the **X-If-Modified-Since-Version** header and/or
the **newer** parameter to the last known value of **X-Last-Modified-Version**
on the target resource.

To avoid overwriting changes made by others, clients should set the
**X-If-Unmodified-Since-Version** header to the last known value of
**X-Last-Modified-Version** on the target resource.


Examples
========

Example: polling for changes to a BSO
-------------------------------------

To efficiently check for changes to an individual BSO, use
**GET /storage/<collection>/<id>** with the **X-If-Modified-Since-Version**
header set to the last known value of **X-Last-Modified-Version** for that
item. This will return the updated item if it has been changed since the last
request, and give a **304 Not Modified** response if it has not::

    last_modified = 0
    while True:
        headers = {"X-If-Modified-Since-Version": last_modified}
        r = server.get("/collection/id", headers)
        if r.status != 304:
            print " MODIFIED ITEM: ", r.json_body
            last_modified = r.headers["X-Last-Modified-Version"]


Example: polling for changes to a collection
--------------------------------------------

To efficiently poll the server for changes within a collection, use
**GET /storage/<collection>** with the **newer** parameter set to the last
known value of **X-Last-Modified-Version** for that collection.  This will
return only the BSOs that have been added or changed since the last request::

    last_modified = 0
    while True:
        r = server.get("/collection?newer=" + last_modified)
        for item in r.json_body["items"]:
            print "MODIFIED ITEM: ", item
        last_modified = r.headers["X-Last-Modified-Version"]


Example: safely updating items in a collection
----------------------------------------------

To update items in a collection without overwriting any changes made
by other clients, use **POST /storage/<collection>** with the
**X-If-Unmodified-Since-Version** header set to the last known value of
**X-Last-Modified-Version** for that collection. If other clients have made
changes to the collection since the last request, the write will fail with
a **412 Precondition Failed** response::

    r = server.get("/collection")
    last_modified = r.headers["X-Last-Modified-Version"]

    bsos = generate_changes_to_the_collection()

    headers = {"X-If-Unmodified-Since-Version": last_modified}
    r = server.post("/collection", bsos, headers)
    if r.status == 412:
        print "WRITE FAILED DUE TO CONCURRENT EDITS"

The client may choose to abort the write, or to merge the changes from the
server and re-try with an updated value of **X-Last-Modified-Version**.

A similar technique can be used to safely update a single BSO using
**PUT /storage/<collection>/<id>**.


Example: creating a BSO only if it does not exist
-------------------------------------------------

To specify that a BSO should be created only if it does not already exist,
use the **X-If-Unodified-Since-Version** header with the special version
number value of 0::

    headers = {"X-If-Unmodified-Since-Version": "0"}
    r = server.put("/collection/item", data, headers)
    if r.status == 412:
        print "ITEM ALREADY EXISTS"


.. _syncstorage_paging:

Example: paging through a large set of items
--------------------------------------------

The syncstorage server allows efficient paging through a large set of items
by using the **limit** and **offset** parameters.

Clients should begin by issuing a **GET /storage/<collection>?limit=<LIMIT>**
request, which will return up to *<LIMIT>* items.  If there were additional
items matching the query, the response will include an *X-Next-Offset* header
to let subsequent requests skip over the items that were just returned.

To fetch additional items, repeat the request using the value from
*X-Next-Offset* as the **offset** parameter.  If the response includes a new
*X-Next-Offset* value, then there are yet more items to be fetched and the
process should be repeated; if it does not then all available items have been
returned.

To guard against other clients making concurrent changes to the
collection, this technique should always be combined with the
**X-If-Unmodified-Since-Version** header as shown below::

    r = server.get("/collection?limit=100")
    print "GOT ITEMS: ", r.json_body["items"]

    last_modified = r.headers["X-Last-Modified-Version"]
    next_offset = r.headers.get("X-Next-Offset")

    while next_offset:
        headers = {"X-If-Unmodified-Since-Version": last_modified}
        r = server.get("/collection?limit=100&offset=" + next_offset, headers)

        if r.status == 412:
            print "COLLECTION WAS MODIFIED WHILE READING ITEMS"
            break

        print "GOT ITEMS: ", r.json_body["items"]
        next_offset = r.headers.get("X-Next-Offset")


Changes from v1.1
=================

The following is a summary of protocol changes from
:ref:`server_storage_api_11`:

* The term "Weave" is no longer used anywhere in the protocol:
    * "Weave Basic Objects" have been renamed "Basic Storage Objects".
    * The "Weave" prefix has been removed from all custom headers.

* Authentication is now performed using the Sagrada TokenServer flow and
  MAC Access Authentication.

* The structure of the endpoint URL is no longer specified, and should be
  considered an implementation detail specific to the server.

* The WBO fields "parentid" and "predecessorid" have been removed, along with
  the corresponding query parameters on all requests.

* Timestamps are now reported in integer milliseconds rather than decimal
  seconds.

* Opaque integer version numbers are now used for tracking and coordination,
  rather than timestamps.

* Integer error codes have been replaced by cornice-format error descriptions
  to allow more flexible and precise error reporting.

* The **GET /info/quota** request now returns an object with keys named "usage"
  and "quota", rather than just a list of numbers.

* Usage and quotas are now reported in integer bytes, not float kibibytes.

* The **GET /storage/collection** request now returns a JSON object rather than
  a JSON list, to guard against certain security issues in older browsers.

* The query parameters for **DELETE /storage/collection** have been removed.
  The only operations now supported are "delete these specific ids" and
  "delete the whole collection".

* The **POST /storage/collection** request now accepts application/newlines
  input in addition to application/json.

* The *X-Last-Modified-Version* header has been added, to provide clients with
  a more robust conflict-detection mechanism than the *X-Timestamp* header.

* The **POST /storage/collection** request no longer returns **modified** as
  part of its output, since the last-modified version is available in the
  *X-Last-Modified-Version* header.

* The **POST /storage/collection/item** request has been added to allow
  partial updates of an individual BSO.  Previously partial updates were
  allowed as part of a **PUT** request, which violated the HTTP semantics
  for **PUT**.

* Successful writes to an individual item now give a **201 Created** or
  **204 No Content** response, rather than redundantly returning a
  modification time and an *X-Last-Modified-Version* header.

* Successful **DELETE** requests now give a **204 No Content** response,
  response, rather than redundantly returning a modification time and an
  *X-Last-Modified-Version* header.

* The **application/whoisi** output format has been removed.

* The **index_above** and **index_below** parameters have been removed.

* The **offset** parameter is now a server-generated value used to page
  through a set of results.  Clients must not attempt to create their
  own values for this parameter.

* The *X-If-Modified-Since-Version* header has been added and can be used on
  all GET requests.

* The *X-If-Unmodified-Since* header is now *X-If-Unmodified-Since-Version*
  and can be used on GET requests to collections and items.

* The previously-undocumented *X-Weave-Quota-Remaining* header has been
  documented, after removing the "Weave" prefix.

* The *X-Weave-Records* header has been renamed to *X-Num-Records*.

* The *X-Weave-Alert* header has been removed.

* The *X-Confirm-Delete* header has been removed.

* The server may refuse service to known-bad clients by returning a
  "403 Forbidden" response.

* The following response codes are explicitly mentioned: 201, 204, 304, 403,
  405, 409, 412, 413.

* Various details of how Firefox Sync is implemented are no longer emphasized,
  since the protocol is being opened up for other applications.

