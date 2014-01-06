.. _server_syncstorage_api_12

====================
SyncStorage API v1.2
====================

The SyncStorage API defines a HTTP web service used to store and retrieve
simple objects called **Basic Storage Objects** (**BSOs**), which are organized
into named **collections**.


Concepts
========

.. _syncstorage_bso:

Basic Storage Object
--------------------

A **Basic Storage Object (BSO)** is the generic JSON wrapper around all
items passed into and out of the SyncStorage server. Like all JSON documents,
BSOs are composed of unicode character data rather than raw bytes and must
be encoded for transmission over the network.  The SyncStorage service always
encodes BSOs in UTF8.

Basic Storage Objects have the following fields:


+---------------+-----------+------------+---------------------------------------------------------------+
| Parameter     | Default   | Type/Max   |  Description                                                  |
+===============+===========+============+===============================================================+
| id            | required  |  string,   | An identifying string. For a user, the id must be unique for  |
|               |           |  64        | a BSO within a collection, though objects in different        |
|               |           |            | collections may have the same ID.                             |
|               |           |            |                                                               |
|               |           |            | BSO ids *must* only contain characters from the urlsafe-base64|
|               |           |            | alphabet (i.e. alphanumerics, underscore and hyphen).  They   |
|               |           |            | *should* be exactly 12 characters; while this isn't enforced  |
|               |           |            | by the server, the Firefox client expects it in most cases.   |
+---------------+-----------+------------+---------------------------------------------------------------+
| modified      | none      | float,     | The timestamp at which this object was last modified, in      |
|               |           | 2 decimal  | seconds since UNIX epoch (1970-01-01 00:00:00 UTC).           |
|               |           | places     | This is set automatically by the server according to its own  |
|               |           |            | clock; any client-supplied value for this field is ignored.   |
+---------------+-----------+------------+---------------------------------------------------------------+
| sortindex     | none      | integer,   | An integer indicating the relative importance of this item in |
|               |           | positive,  | the collection.                                               |
|               |           | 9 digits   |                                                               |
+---------------+-----------+------------+---------------------------------------------------------------+
| payload       | empty     | string,    | A string containing the data of the record. The structure of  |
|               | string    | 256k       | this string is defined separately for each BSO type. This     |
|               |           |            | spec makes no requirements for its format. In practice,       |
|               |           |            | JSONObjects are common.                                       |
+---------------+-----------+------------+---------------------------------------------------------------+
| ttl           | none      | integer,   | The number of seconds to keep this record. After that time    |
|               |           | positive,  | this item will no longer be returned in response to any       |
|               |           | 9 digits   | request, and it may be pruned from the database.  If not      |
|               |           |            | specified or null, the record will not expire.                |
|               |           |            |                                                               |
|               |           |            | This field may be set on write, but is not returned by the    |
|               |           |            | server.                                                       |
+---------------+-----------+------------+---------------------------------------------------------------+


Example::

    {
      "id": "-F_Szdjg3GzY",
      "modified": 1388635807.41,
      "sortindex": 140,
      "payload": "{ \"this is\": \"an example\" }
    }


Collections
-----------

Each BSO is assigned to a collection with other related BSO. Collection names
may be up to 32 characters long, and must contain only characters from the
urlsafe-base64 alphaebet (i.e. alphanumeric characters, underscore and hyphen)
and the period.

Collections are created implicitly when a BSO is stored in them for the first
time.  They continue to exist until they are explicitly deleted, even if they
no longer contain any BSOs.

The default collections used by Firefox to store sync data are:

* bookmarks
* history
* forms
* prefs
* tabs
* passwords

The following additional collections are used for internal management purposes
by the storage client:

* clients
* crypto
* keys
* meta


Timestamps
----------

In order to allow multiple clients to coordinate their changes, the SyncStorage
server associates a **last-modified time** with the data stored for each user.
This is a server-assigned decimal value, precise to two decimal places, that is updated
from the server's clock with every modification made to the user's data.

The last-modified time is tracked at three levels of nesting:

    * The store as a whole has a **last-modified time** that is updated whenever
      any change is made to the user's data.
    * Each collection has a **last-modified time** that is updated whenever an item
      in that collection is modified or deleted. It will always be less than or
      equal to the overall last-modified time.
    * Each BSO has a **last-modified time** that is updated whenever that specific
      item is modified.   It will always be less than or equal to the last-modified
      time of the containing collection.

The last-modified time is guaranteed to be monotonically increasing and can be
used for coordination and conflict management as described in
:ref:`syncstorage_concurrency`.


API Access and Discovery
========================


The SyncStorage data for a given user may be accessed via authenticated
HTTP requests to their SyncStorage API endpoint.  All requests will be
to URLs of the form::

    https://<endpoint-url>/<api-instruction>

The user's SyncStorage endpoint URL can be obtained via the Sagrada Discovery
and Authentication workflow [1]_.  All requests must be signed using HAWK
Access Authentication credentials [2]_.

Request and response bodies are all UTF8-encoded JSON unless otherwise specified.

Error responses generated by the SyncStorage server will, wherever possible,
conform to the :ref:`respcodes` defined for the User API.
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
    the last-modified time for each collection.

    Possible HTTP status codes:

    - **304 Not Modified:**  the current last-modified time is less than or equal
      to the value specified in the *X-If-Modified-Since* header.


**GET** **https://<endpoint-url>/info/quota**

    Returns a two-item list giving the user's current usage and quota
    (in KB).  The second item will be null if the server does not enforce
    quotes.

    Note that usage numbers may be approximate.

    Possible HTTP status codes:

    - **304 Not Modified:**  the current last-modified time is less than or equal
      to the value specified in the *X-If-Modified-Since* header.


**GET** **https://<endpoint-url>/info/collection_usage**

    Returns an object mapping collection names associated with the account to
    the data volume used for each collection (in KB).

    Note that this request may be very expensive as it calculates more
    detailed and accurate usage information than the request to
    **/info/quota**.

    Possible HTTP status codes:

    - **304 Not Modified:**  the current last-modified time is less than or equal
      to the value specified in the *X-If-Modified-Since* header.


**GET** **https://<endpoint-url>/info/collection_counts**

    Returns an object mapping collection names associated with the account to
    the total number of items in each collection.

    Possible HTTP status codes:

    - **304 Not Modified:**  the current last-modified time is less than or equal
      to the value specified in the *X-If-Modified-Since* header.


Individual Collection Interaction
---------------------------------

APIs in this section provide a mechanism for interacting with a single
collection.

**GET** **https://<endpoint-url>/storage/<collection>**

    Returns a list of the BSOs contained in a collection.  For example::

        ["GXS58IDC_12", "GXS58IDC_13", "GXS58IDC_15"]

    By default only the BSO ids are returned, but full objects can be requested
    using the **full** parameter.

    This request has additional optional query parameters:

    - **ids**: a comma-separated list of ids. Only objects whose id is in this
      list will be returned.  A maximum of 100 ids may be provided.

    - **newer**: a timestamp. Only objects whose last-modified time is
      strictly greater than this value will be returned.

    - **full**: any value.  If provided then the response will be a list of
      full BSO objects rather than a list of ids.

    - **limit**: a positive integer. At most that many objects will be
      returned. If more than that many objects matched the query, an
      *X-Weave-Next-Offset* header will be returned.

    - **offset**: a string, as returned in the *X-Weave-Next-Offset* header of
      a previous request using the **limit** parameter.

    - **sort**: sorts the output:
       - 'newest' - orders by last-modified time, largest first
       - 'index' - orders by the sortindex, highest weight first

    The response will include an *X-Weave-Records* header indicating the
    total number of records to expect in the body.

    If the request included a **limit** parameter and there were more than
    that many items matching the query, the response will include an
    *X-Weave-Next-Offset* header.  This value can be passed back to the server in
    the **offset** parameter to efficiently skip over the items that have
    already been read.  See :ref:`syncstorage_paging` for an example.

    Two output formats are available for multiple record GET requests.
    They are triggered by the presence of the appropriate format in the
    *Accept* request header and are prioritized in the order listed below:

    - **application/json**: the output is a JSON list of the request records,
      as either string ids or full JSON objects.
    - **application/newlines**: the output contains each record on a separate
      line, as either a string id or a full JSON object.

    Possible HTTP status codes:

    - **304 Not Modified:**  the last-modified time of the collection
      is less than or equal to the value in the *X-If-Modified-Since* header.
    - **400 Bad Request:**  too many ids where included in the query parameter.
    - **404 Not Found:**  the user has no such collection.
    - **412 Precondition Failed:**  the last-modified time of the collection
      is greater than the value in the *X-If-Unmodified-Since* header.
      


**GET** **https://<endpoint-url>/storage/<collection>/<id>**

    Returns the BSO in the collection corresponding to the requested id

    Possible HTTP error responses:

    - **304 Not Modified:**  the last-modified time of the item is
      less than or equal to the value in the *X-If-Modified-Since* header.
    - **404 Not Found:**  the user has no such collection, or it contains
      no such object.
    - **412 Precondition Failed:**  the last-modified time of the item
      is greater than the value in the *X-If-Unmodified-Since* header.


**PUT** **https://<endpoint-url>/storage/<collection>/<id>**

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

    This request may include the *X-If-Unmodified-Since* header to
    avoid overwriting the data if it has been changed since the client
    fetched it.

    Successful responses will have a JSON object body with field "modified"
    giving the new last-modified time for the collection.

    Note that the server may impose a limit on the amount of data submitted
    for storage in a single BSO.

    Possible HTTP error responses:

    - **400 Bad Request:**  the user has exceeded their storage quota.
    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.
    - **412 Precondition Failed:**  the last-modified time  of the item
      is greater than the value in the *X-If-Unmodified-Since* header.
    - **413 Request Entity Too Large:**  the object is larger than the
      server is willing to store.
    - **415 Unsupported Media Type:**  the request had a Content-Type other
      than **application/json**.


**POST** **https://<endpoint-url>/storage/<collection>**

    Takes a list of BSOs in the request body and iterates over them,
    effectively doing a series of individual PUTs with the same timestamp.

    Each BSO record in the request body must include an "id" field, and the
    corresponding BSO will be created or updated according to the semantics
    of a **PUT** request targeting that specific record.  In particular,
    this means that fields not provided in the request body will not be
    overwritten on BSOs that already exist.

    Successful responses will contain a JSON object with details of success
    or failure for each BSO.  It will have the following keys:

    - **modified:** the new last-modified time for the updated items.
    - **success:** a list of ids of BSOs that were successfully stored.
    - **failed:** an object whose keys are the ids of BSOs that were not
      stored successfully, and whose values are lists of strings
      describing possible reasons for the failure.

    For example::

        {
         "modified": 1233702554.25,
         "success": ["GXS58IDC_12", "GXS58IDC_13", "GXS58IDC_15",
                     "GXS58IDC_16", "GXS58IDC_18", "GXS58IDC_19"],
         "failed": {"GXS58IDC_11": ["invalid ttl"],
                    "GXS58IDC_14": ["invalid sortindex"]}
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
    number of BSOs in a single request.  The default limit on the number
    of BSOs per request is 100.

    Possible HTTP error responses:

    - **400 Bad Request:**  the user has exceeded their storage quota.
    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.
    - **412 Precondition Failed:**  the last-modified time of the collection is greater
      than the value in the *X-If-Unmodified-Since* header.
    - **413 Request Entity Too Large:**  the request contains more data than the
      server is willing to process in a single batch.
    - **415 Unsupported Media Type:**  the request had a Content-Type other
      than **application/json** or **application/newlines**.


**DELETE** **https://<endpoint-url>/storage/<collection>**

    Deletes an entire collection.

    After executing this request, the collection will not appear 
    in the output of **GET /info/collections** and calls to
    **GET /storage/<collection>** will generate a **404 Not Found**
    response.

    Possible HTTP error responses:

    - **404 Not Found:**  the user has no such collection.
    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.
    - **412 Precondition Failed:**  the last-modified time of the collection
      is greater than the value in the *X-If-Unmodified-Since* header.


**DELETE** **https://<endpoint-url>/storage/<collection>?ids=<ids>**

    Deletes multiple BSOs from a collection with a single request.

    This request takes a parameter to select which items to delete:

    - **ids**: deletes BSOs from the collection whose ids that are in
      the provided comma-separated list.  A maximum of 100 ids may be
      provided.

    The collection itself will still exist on the server after executing
    this request.  Even if all the BSOs in the collection are deleted, it
    will receive an updated last-modified time, appear in the output of
    **GET /info/collections**, and be readable via **GET /storage/<collection>**

    Successful responses will have a JSON object body with field "modified"
    giving the new last-modified time for the collection.

    Possible HTTP error responses:

    - **400 Bad Request:**  too many ids where included in the query parameter.
    - **404 Not Found:**  the user has no such collection.
    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.
    - **412 Precondition Failed:**  the last-modified time of the collection is
      greater than the value in the *X-If-Unmodified-Since* header.


**DELETE** **https://<endpoint-url>/storage/<collection>/<id>**

    Deletes the BSO at the given location.

    Possible HTTP error responses:

    - **404 Not Found:**  the user has no such collection, or it contains
      no such object.
    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.
    - **412 Precondition Failed:**  the last-modified time of the item
      is greater than the value in the *X-If-Unmodified-Since* header.


Multi-Collection Interaction
----------------------------

APIs in this section are used for interaction with multiple collections.

**DELETE** **https://<endpoint-url>/storage**

    Deletes all records for the user.

    Possible HTTP error responses:

    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.


Request Headers
===============

**X-If-Modified-Since**

    This header may be added to any GET request, set to a timestamp with two
    decimal places of precision. If the last-modified time of the target
    resource is less than or equal to the time given in this header, then a
    **304 Not Modified** response will be returned and re-transmission of
    the unchanged data will be avoided.

    It is similar to the standard HTTP **If-Modified-Since** header, but the
    value is a decimal timestamp rather than a HTTP-format date.

    If the value of this header is not a valid positive decimal value, or if the
    **X-If-Unmodified-Since** header is also present, then a **400 Bad Request**
    response will be returned.


**X-If-Unmodified-Since**

    This header may be added to any request to a collection or item, set to a
    timestamp with two decimal places of precision.  If the last-modified time
    of the target resource is greater than the time given, the request will fail
    with a **412 Precondition Failed** response.

    It is similar to the standard HTTP **If-Unmodified-Since** header, but the
    value is a decimal timestamp rather than a HTTP-format date.

    If the value of this header is not a valid positive decimal value, or if the
    **X-If-Modified-Since** header is also present, then a **400 Bad Request**
    response will be returned.


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

**X-Weave-Backoff**

    This header may be sent to indicate that the server is under heavy load
    but is still capable of servicing requests.  Unlike the **Retry-After**
    header, **X-Weave-Backoff** may be included with any type of response, including
    a **200 OK**.

    Clients should perform the minimum number of additional requests required
    to maintain consistency of their stored data, then not attempt any further
    requests for the number of seconds specified in the header value.

**X-Last-Modified**

    This header gives the last-modified time of the target resource
    as seen during processing of the request, and will be included in all
    success responses (200, 201, 204).  When given in response to a write
    request, this will be equal to the server's current time and to the new
    last-modified time of any BSOs created or changed by the request.

    It is similar to the standard HTTP **Last-Modified** header, but the value
    is a decimal timestamp rather than a HTTP-format date.

**X-Weave-Timestamp**

    This header will be sent back with all responses, indicating the current
    timestamp on the server.  When given in response to a write request, this
    will be equal to the new timestamp value of any BSOs created or changed
    by that request.

    It is similar to the standard HTTP **Date** header, but the value is
    a decimal timestamp rather than a HTTP-format date.

**X-Weave-Records**

    This header may be sent back with multi-record responses, to indicate the
    total number of records included in the response.

**X-Weave-Next-Offset**

    This header may be sent back with multi-record responses where the request
    included a **limit** parameter.  Its presence indicates that the number of
    available records exceeded the given limit.  The value from this header
    can be passed back in the **offset** parameter to retrieve additional
    records.

    The value of this header will always be a string of characters from the
    urlsafe-base64 alphabet.  The specific contents of the string are an
    implementation detail of the server, so clients should treat it as an
    opaque token.

**X-Weave-Quota-Remaining**

    This header may be returned in response to write requests, indicating
    the amount of storage space remaining for the user (in KB).  It will
    not be returned if quotas are not enabled on the server.

**X-Weave-Alert**

    This header may be returned in response to any request, and contains
    potential warning messages, information, or other alerts.

    If the first character of the header is not "{" then it is intended to
    be a human-readable string that may be included in logs.

    If the first character of the header is "{" then it is a JSON object
    signalling impending shutdown of the service.  It will contain the
    following fields:

        * **code:** one of the strings "soft-eol" or "hard-eol".
        * **message:** a human-readable message that may be included in logs.
        * **url:** a URL at which more information is available.


HTTP status codes
=================

Since the syncstorage protocol is implemented on top of HTTP, clients should be
prepared to deal gracefully with any valid HTTP response.  This section serves
to highlight the response codes that explicitly form part of the syncstorage
protocol.

**200 OK**

    The request was processed successfully, and the server is returning
    useful information in the response body.


**304 Not Modified**

    For requests that include the *X-If-Modified-Since* header, this
    response code indicates that the resource has not been modified.  The
    client should continue to use its local copy of the data.


**400 Bad Request**

    The request itself or the data supplied along with the request is invalid
    and could not be processed by the server.  For example, this response will
    be returned if a header value is incorrectly formatted or if a JSON request
    body cannot be parsed.

    If the response has a *Content-Type* of **application/json** then the body
    will be an integer response code as documented in :ref:`respcodes`.


**401 Unauthorized**

    The authentication credentials are invalid on this node. This may be caused
    by a node reassignment or by an expired/invalid auth token. The client
    should check with the tokenserver whether the user's endpoint URL has changed.
    If it has changed, the current sync is to be aborted and should be retried
    against the new endpoint URL.


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
    without violating its consistency guarantees.

    The client should retry the request after accounting for any changes
    introduced by other clients.

    This response may include a *Retry-After* header indicating the time after
    which the conflicting edits are expected to complete.  If present, clients
    should wait at least this many seconds before retrying the request.


**412 Precondition Failed**

    For requests that included the *X-If-Unmodified-Since* header, this
    response code indicates that the resource has in fact been modified more
    recently than the given time.  The requested write operation will not have
    been performed.


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

**513 Service Decommissioned**

    Indicates that the service has been decommissioned, and presumably replaced
    with a new and better service using some as-yet-undesigned protocol.
    This response will include an *X-Weave-Alert* header whose value is a
    JSON object with the following fields:

        * **code:** the string "hard-eol".
        * **message:** a human-readable message that may be included in logs.
        * **url:** a URL at which more information is available.

    The client should display an appropriate message to the user and cease
    any further attempts to use the service.


.. _syncstorage_concurrency:

Concurrency and Conflict Management
===================================

The SyncStorage service allows multiple clients to synchronize data via
a shared server without requiring inter-client coordination or blocking.
To achieve proper synchronization without skipping or overwriting data,
clients are expected to use timestamp-driven coordination features such
as **X-Last-Modified** and **X-If-Unmodified-Since**.

The server guarantees a strictly consistent and monotonically-increasing
timestamp across the user's stored data.  Any request that alters the
contents of a collection will cause the last-modified time to increase.
Any BSOs added or modified by such a request will have their "modified" field
set to the updated timestamp.

Conceptually, each write request will perform the following operations as
an atomic unit:

  * Read the current time `T`, and check that it's greater than the overall
    last-modified time for the user's data.  If not then return a **409 Conflict**.
  * Create any new BSOs as specified by the request, setting their "modified"
    field to `T`.
  * Modify any existing BSOs as specified by the request, setting their
    "modified" field to `T`.
  * Delete any BSOs as specified by the request.
  * Set the last-modified time for the collection to `T`.
  * Set the overall last-modified time for the user's data to `T`.
  * Generate a **200 OK** response with the **X-Last-Modified** and
    **X-Weave-Timestamp** headers set to `T`.

While write requests from different clients may be processed concurrently
by the server, they will appear to the clients to have occurred sequentially,
instantaneously and atomically according to the above sequence.

To avoid having the server transmit data that has not changed since the last
request, clients should set the **X-If-Modified-Since** header and/or
the **newer** parameter to the last known value of **X-Last-Modified**
on the target resource.

To avoid overwriting changes made by others, clients should set the
**X-If-Unmodified-Since** header to the last known value of
**X-Last-Modified** on the target resource.


Examples
========

Example: polling for changes to a BSO
-------------------------------------

To efficiently check for changes to an individual BSO, use
**GET /storage/<collection>/<id>** with the **X-If-Modified-Since**
header set to the last known value of **X-Last-Modified** for that
item. This will return the updated item if it has been changed since the last
request, and give a **304 Not Modified** response if it has not::

    last_modified = 0
    while True:
        headers = {"X-If-Modified-Since": last_modified}
        r = server.get("/collection/id", headers)
        if r.status != 304:
            print " MODIFIED ITEM: ", r.json_body
            last_modified = r.headers["X-Last-Modified"]


Example: polling for changes to a collection
--------------------------------------------

To efficiently poll the server for changes within a collection, use
**GET /storage/<collection>** with the **newer** parameter set to the last
known value of **X-Last-Modified** for that collection.  This will
return only the BSOs that have been added or changed since the last request::

    last_modified = 0
    while True:
        r = server.get("/collection?newer=" + last_modified)
        for item in r.json_body["items"]:
            print "MODIFIED ITEM: ", item
        last_modified = r.headers["X-Last-Modified"]


Example: safely updating items in a collection
----------------------------------------------

To update items in a collection without overwriting any changes made
by other clients, use **POST /storage/<collection>** with the
**X-If-Unmodified-Since** header set to the last known value of
**X-Last-Modified** for that collection. If other clients have made
changes to the collection since the last request, the write will fail with
a **412 Precondition Failed** response::

    r = server.get("/collection")
    last_modified = r.headers["X-Last-Modified"]

    bsos = generate_changes_to_the_collection()

    headers = {"X-If-Unmodified-Since": last_modified}
    r = server.post("/collection", bsos, headers)
    if r.status == 412:
        print "WRITE FAILED DUE TO CONCURRENT EDITS"

The client may choose to abort the write, or to merge the changes from the
server and re-try with an updated value of **X-Last-Modified**.

A similar technique can be used to safely update a single BSO using
**PUT /storage/<collection>/<id>**.


Example: creating a BSO only if it does not exist
-------------------------------------------------

To specify that a BSO should be created only if it does not already exist,
use the **X-If-Unmodified-Since** header with the special value of 0::

    headers = {"X-If-Unmodified-Since": "0"}
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
items matching the query, the response will include an *X-Weave-Next-Offset* header
to let subsequent requests skip over the items that were just returned.

To fetch additional items, repeat the request using the value from
*X-Weave-Next-Offset* as the **offset** parameter.  If the response includes a new
*X-Weave-Next-Offset* value, then there are yet more items to be fetched and the
process should be repeated; if it does not then all available items have been
returned.

To guard against other clients making concurrent changes to the
collection, this technique should always be combined with the
**X-If-Unmodified-Since** header as shown below::

    r = server.get("/collection?limit=100")
    print "GOT ITEMS: ", r.json_body["items"]

    last_modified = r.headers["X-Last-Modified"]
    next_offset = r.headers.get("X-Weave-Next-Offset")

    while next_offset:
        headers = {"X-If-Unmodified-Since": last_modified}
        r = server.get("/collection?limit=100&offset=" + next_offset, headers)

        if r.status == 412:
            print "COLLECTION WAS MODIFIED WHILE READING ITEMS"
            break

        print "GOT ITEMS: ", r.json_body["items"]
        next_offset = r.headers.get("X-Weave-Next-Offset")


Changes from v1.1
=================

The following is a summary of protocol changes from
:ref:`server_storage_api_11` along with a justification for each change:

+-------------------------------------------+---------------------------------------------------+
| What Changed                              | Why                                               |
+===========================================+===================================================+
| Authentication is now performed using     | This supports authentication via Firefox Accounts |
| the Sagrada TokenServer flow and HAWK     | and allows us to iterate the details of that      |
| Access Authentication.                    | flow without changing the sync protocol.          |
+-------------------------------------------+---------------------------------------------------+
| The structure of the endpoint URL is      | This was unnecessary coupling and clients do      |
| no longer specified, and should be        | not need to change/configure components of the    |
| considered an implementation detail.      | endpoint URL.  URL handling must change already   |
|                                           | to support TokenServer-based authentication.      |
+-------------------------------------------+---------------------------------------------------+
| The datatypes and defaults of BSO         | This reflects current server behavior, and seems  |
| fields are more precisely specified.      | prudent to specify more explicitly.               |
+-------------------------------------------+---------------------------------------------------+
| The BSO fields "parentid" and             | These were deprecated in version 1.1 and are not  |
| "predecessorid" have been removed along   | in active use in current versions of Firefox.     |
| with any related query parameters.        |                                                   |
+-------------------------------------------+---------------------------------------------------+
| The 'application/whoisi' output format    | This is not used in any current versions of       |
| has been removed.                         | Firefox.                                          |
+-------------------------------------------+---------------------------------------------------+
| The previously-undocumented               | This actually *is* used so we better document it. |
| *X-Weave-Quota-Remaining* header has been |                                                   |
+-------------------------------------------+---------------------------------------------------+
| The *X-Confirm-Delete* header has been    | This is sent unconditionally by current client    |
| removed.                                  | code, and is therefore useless.  Existing client  |
|                                           | code can safely continue to send it, and it will  |
|                                           | be ignored by the server.                         |
+-------------------------------------------+---------------------------------------------------+
| The *X-Weave-Alert* header has grown      | This is already implemented in current Firefox so |
| additional semantics related to service   | we better document it.                            |
| end-of-life announcements.                |                                                   |
+-------------------------------------------+---------------------------------------------------+
| **GET /storage/collection** no longer     | These are not in active use in current versions   |
| accepts 'older', 'index_above',           | of Firefox, and impose additional requirements on |
| 'index_below' or 'sort=oldest'.           | the server that may limit operational flexibility.|
+-------------------------------------------+---------------------------------------------------+
| **DELETE /storage/collection** no longer  | These are not in active use in current versions   |
| accepts query parameters other than 'ids' | of Firefox, are not all implemented correctly in  |
|                                           | the current server, and impose additional         |
|                                           | requirements on the server that may limit         |
|                                           | operational flexibility.                          |
+-------------------------------------------+---------------------------------------------------+
| **POST /storage/collection** now accepts  | This matches nicely with 'application/newlines'   |
| 'application/newlines' input in addition  | as supported already in response bodies, and may  |
| to 'application/json'.                    | enable more efficient request streaming in future.|
|                                           | Existing client code doesn't need to change.      |
+-------------------------------------------+---------------------------------------------------+
| The **offset** parameter is now an opaque | The parameter is not in active use in current     |
| server-generated value, and clients must  | versions of Firefox, and its existing semantics   |
| not create their own values for it.       | are difficult to implement efficiently on the     |
|                                           | server.  This change allows for more efficient    |
|                                           | pagination of results in future client code.      |
+-------------------------------------------+---------------------------------------------------+
| The *X-Last-Modified* header has been     | This has slightly different semantics to the      |
| added.                                    | *X-Weave-Timestamp* header and may be used by     |
|                                           | future clients for better conflict management.    |
|                                           | Existing client code doesn't need to change.      |
+-------------------------------------------+---------------------------------------------------+
| The *X-If-Modified-Since* header has been | Existing client code doesn't need to change, but  |
| added and can be used on all GET request. | will allow future client code to avoid            |
|                                           | transmission of redundant data.                   |
+-------------------------------------------+---------------------------------------------------+
| The *X-If-Unmodified-Since* header can be | Existing client code doesn't need to change, but  |
| used on some GET request.                 | will allow future client code to detect changes   |
|                                           | during paginated fetching of results.             |
+-------------------------------------------+---------------------------------------------------+
| The server may reject concurrent write    | This **will** be visible to existing client code, |
| attempts with a **409 Conflict**.         | but can be handled like a **503** error.  It lets |
|                                           | the server provide much stronger consistency      |
|                                           | guarantees that will improve overall robustness   |
|                                           | of the service.                                   |
+-------------------------------------------+---------------------------------------------------+

