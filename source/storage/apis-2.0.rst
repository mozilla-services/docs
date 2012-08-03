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


.. _syncstorage_wbo:

Basic Storage Object
====================

A **Basic Storage Object (BSO)** is the generic JSON wrapper around all
items passed into and out of the SyncStorage server. Like all JSON, Basic
Storage Objects need to be UTF-8 encoded. BSOs have the following fields:

+---------------+-----------+------------+---------------------------------------------------------------+
| Parameter     | Default   | Type/Max   |  Description                                                  |
+===============+===========+============+===============================================================+
| id            | required  |  string    | An identifying string. For a user, the id must be unique for  |
|               |           |  64        | a BSO within a collection, though objects in different        |
|               |           |            | collections may have the same ID.                             |
|               |           |            |                                                               |
|               |           |            | BSO ids may only contain characters from the urlsafe-base64   |
|               |           |            | alphabet (i.e. alphanumerics, underscore and hyphen)          |
+---------------+-----------+------------+---------------------------------------------------------------+
| modified      | time      | integer    | The last-modified time, in milliseconds since UNIX epoch      |
|               | submitted |            | (1970-01-01 00:00:00 UTC).  This is set automatically by the  |
|               |           |            | server; any client-supplied value for this field is ignored.  |
+---------------+-----------+------------+---------------------------------------------------------------+
| sortindex     | none      | integer    | An integer indicating the relative importance of this item in |
|               |           | 9 digits   | the collection.                                               |
+---------------+-----------+------------+---------------------------------------------------------------+
| payload       | none      | string     | A string containing the data of the record. The structure of  |
|               |           | 256k       | this string is defined separately for each BSO type. This     |
|               |           |            | spec makes no requirements for its format. In practice,       |
|               |           |            | JSONObjects are common.                                       |
+---------------+-----------+------------+---------------------------------------------------------------+
| ttl           | none      | integer    | The number of seconds to keep this record. After that time    |
|               |           |            | this item will no longer be returned in response to any       |
|               |           |            | request, and it may be pruned from the database.              |
+---------------+-----------+------------+---------------------------------------------------------------+


Example::

    {
      "id": "-F_Szdjg3GzY",
      "modified": 1278109839960,
      "sortindex": 140,
      "payload": "THIS IS AN EXAMPLE"
    }


Collections
===========

Each BSO is assigned to a collection with other related BSOs. Collection names
may only contain characters from the urlsafe-base64 alphabet (i.e. alphanumeric
characters, underscore and hyphen).

Collections are created implicitly when a BSO is stored in them for the first
time.  They continue to exist until they are explicitly deleted, even if they
no longer contain any BSOs.

Each collection has a last-modified timestamp corresponding to the time of
the last BSO addition, deletion or modification in the collection.  The
timestamp of an empty collection gives the time of deletion of its last BSO.

The last-modified timestamp can be used for coordination and conflict
management as described in :ref:`syncstorage_concurrency`.


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

The SyncStorage API has a set of :ref:`respcodes` to cover errors in the
request or on the server side. The format of a successful response is
defined in the appropriate request method section.


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
    the last modified timestamp for each collection.

    Possible HTTP status codes:

    - **304 Not Modified:**  no collections have been modified or deleted
      since the timestamp in the *X-If-Modified-Since* header.


**GET** **https://<endpoint-url>/info/quota**

    Returns an object giving details of the user's current usage and
    quota.  It will have the following keys:

    - **usage**:  the user's total current usage in bytes.
    - **quota**:  the user's total quota in bytes
                  (or null if quotas are not in use)

    Note that usage numbers may be approximate.

    Possible HTTP status codes:

    - **304 Not Modified:**  no collections have been modified or deleted
      since the timestamp in the *X-If-Modified-Since* header.


**GET** **https://<endpoint-url>/info/collection_usage**

    Returns an object mapping collection names associated with the account to
    the data volume used for each collection (in bytes).

    Note that this request may be very expensive as it calculates more
    detailed and accurate usage information than the request to
    **/info/quota**.

    Possible HTTP status codes:

    - **304 Not Modified:**  no collections have been modified or deleted
      since the timestamp in the *X-If-Modified-Since* header.


**GET** **https://<endpoint-url>/info/collection_counts**

    Returns an object mapping collection names associated with the account to
    the total number of items in each collection.

    Possible HTTP status codes:

    - **304 Not Modified:**  no collections have been modified or deleted
      since the timestamp in the *X-If-Modified-Since* header.


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
      list will be returned.

    - **older**: a timestamp in milliseconds. Only objects that were last
      modified before this time will be returned.

    - **newer**: a timestamp in milliseconds. Only objects that were last
      modified after this time will be returned.

    - **full**: any value.  If provided then the response will be a list of
      full BSO objects rather than a list of ids.

    - **limit**: an integer. At most that many objects will be returned.
      If more than that many objects matched the query, an *X-Next-Offset*
      header will be returned.

    - **offset**: a string, as returned in the *X-Next-Offset* header of
      a previous request using the **limit** parameter.

    - **sort**: sorts the output:
       - 'oldest' - orders by modification date (oldest first)
       - 'newest' - orders by modification date (newest first)
       - 'index' - orders by the sortindex descending (highest weight first)

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

    - **304 Not Modified:**  no objects in the collection have been modified
      since the timestamp in the *X-If-Modified-Since* header.
    - **404 Not Found:**  the user has no such collection.
    - **412 Precondition Failed:**  an object in the collection has been
      modified since the timestamp in the *X-If-Unmodified-Since* header.


**GET** **https://<endpoint-url>/storage/<collection>/<id>**

    Returns the BSO in the collection corresponding to the requested id

    Possible HTTP error responses:

    - **304 Not Modified:**  the object has not been modified since the
      timestamp in the *X-If-Modified-Since* header.
    - **404 Not Found:**  the user has no such collection, or it contains
      no such object.
    - **412 Precondition Failed:**  the object has been modified
      since the timestamp in the *X-If-Unmodified-Since* header.


**PUT** **https://<endpoint-url>/storage/<collection>/<id>**

    Adds the BSO defined in the request body to the collection. If the BSO
    does not contain a payload, it will only update the provided metadata
    fields on an already defined object.

    This request may include the *X-If-Unmodified-Since* header to avoid
    overwriting the data if it has been changed since the client fetched it.

    Successful requests will receive a **201 Created** response if a new
    BSO is created, or a **204 No Content** response if an existing BSO
    is updated  The response will include an *X-Last-Modified* header giving
    the new modification time of the object.

    Note that the server may impose a limit on the amount of data submitted
    for storage in a single BSO.

    Possible HTTP error responses:

    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.
    - **412 Precondition Failed:**  the object has been modified since the
      timestamp in the *X-If-Unmodified-Since* header.
    - **413 Request Entity Too Large:**  the object is larger than the
      server is willing to store.
    - **415 Unsupported Media Type:**  the request had a Content-Type other
      than **application/json**.


**POST** **https://<endpoint-url>/storage/<collection>**

    Takes a list of BSOs in the request body and iterates over them,
    effectively doing a series of PUTs with the same timestamp.

    Returns an object with details of success or failure for each BSO.
    It will have the following keys:

    - **success:** a list of ids of BSOs that were successfully stored.
    - **failed:** an object whose keys are the ids of BSOs that were not
      stored successfully, and whose values are lists of strings
      describing possible reasons for the failure.

    For example::

        {
         "success": ["GXS58IDC_12", "GXS58IDC_13", "GXS58IDC_15",
                     "GXS58IDC_16", "GXS58IDC_18", "GXS58IDC_19"],
         "failed": {"GXS58IDC_11": ["invalid timestamp"],
                    "GXS58IDC_14": ["invalid timestamp"]}
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
    - **412 Precondition Failed:**  an object in the collection has been
      modified since the timestamp in the *X-If-Unmodified-Since* header.
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

    - **400 Bad Request:**  too many ids where included in the query parameter.
    - **404 Not Found:**  the user has no such collection.
    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.
    - **412 Precondition Failed:**  an object in the collection has been
      modified since the timestamp in the *X-If-Unmodified-Since* header.


**DELETE** **https://<endpoint-url>/storage/<collection>?ids=<ids>**

    Deletes multiple BSOs from a collection with a single request.
    Successful requests will receive a **204 No Content** response.

    This request takes a parameter to select which items to delete:

    - **ids**: deletes BSO from the collection whose ids that are in
      the provided comma-separated list.  A maximum of 100 ids may be
      provided.

    The collection itself will still exist on the server after executing
    this request.  Even if all the BSOs in the collection are deleted, it
    will receive an updated last-modified timestamp, appear in the output
    of **GET /info/collections**, and be readable via
    **GET /storage/<collection>**

    Possible HTTP error responses:

    - **400 Bad Request:**  too many ids where included in the query parameter.
    - **404 Not Found:**  the user has no such collection.
    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.
    - **412 Precondition Failed:**  an object in the collection has been
      modified since the timestamp in the *X-If-Unmodified-Since* header.


**DELETE** **https://<endpoint-url>/storage/<collection>/<id>**

    Deletes the BSO at the given location.
    Successful requests will receive a **204 No Content** response.

    Possible HTTP error responses:

    - **404 Not Found:**  the user has no such collection, or it contains
      no such object.
    - **409 Conflict:**  another client has made (or is currently making)
      changes that may conflict with the requested operation.
    - **412 Precondition Failed:**  the object has been modified since the
      timestamp in the *X-If-Unmodified-Since* header.


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

**X-If-Modified-Since**

    This header may be added to any GET request, set to a timestamp.  If the
    target resource has not been modified since the timestamp given, then a
    **304 Not Modified** response will be returned and re-transmission of the
    unchanged data will be avoided.

    It is similar to the standard HTTP **If-Modified-Since** header, but the
    value is expressed in integer milliseconds for extra precision.

    If the value of this header is not a valid integer, or if the
    **X-If-Unmodified-Since** header is also present, then a
    **400 Bad Request** response will be returned.


**X-If-Unmodified-Since**

    This header may be added to any request to a collection or item, set to a
    timestamp.  If the resource to be acted on has been modified since the
    timestamp given, the request will fail with a **412 Precondition Failed**
    response.

    It is similar to the standard HTTP **If-Unmodified-Since** header, but the
    value is expressed in integer milliseconds for extra precision.

    If the value of this header is not a valid integer, or if the
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

**X-Backoff**

    This header may be sent to indicate that the server is under heavy load
    but is still capable of servicing requests.  Unlike the **Retry-After**
    header, **X-Backoff** may be included with any type of response, including
    a **200 OK**.

    Clients should perform the minimum number of additional requests required
    to maintain consistency of their stored data, then not attempt any further
    requests for the number of seconds specified in the header value.

**X-Last-Modified**

    This header gives the last-modified timestamp of the target resource as
    seen during processing of the request, and will be included in all success
    responses (200, 201, 204).  When given in response to a write request,
    this will be equal to the modified timestamp of any BSOs created or
    changed by the request.

    It is similar to the standard HTTP **Last-Modified** header, but the value
    is expressed in integer milliseconds for extra precision.

**X-Timestamp**

    This header will be sent back with all responses, indicating the current
    timestamp on the server.

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

    For requests the included the *X-If-Modified-Since* header, this response
    code indicates that the resource has not been modified.  The client should
    continue to use its local copy of the data.


**400 Bad Request**

    The request itself or the data supplied along with the request is invalid.
    The response contains a numeric code indicating the reason for why the
    request was rejected. See :ref:`respcodes` for a list of valid response
    codes.


**401 Unauthorized**

    The authentication credentials are invalid on this node. This may be caused
    by a node reassignment or by an expired/invalid auth token. The client
    should check with the auth server whether the user's node has changed. If
    it has changed, the current sync is to be aborted and should be retried
    against the new node.


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

    For requests that include the *X-If-Unmodified-Since* header, this response
    code indicates that the resource was in fact modified.  The requested write
    operation will not have been performed.


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




.. _syncstorage_concurrency:

Concurrency and Conflict Management
===================================

The SyncStorage service allows multiple clients to synchronize data via
a shared server without requiring inter-client coordination or blocking.
To achieve proper synchronization without skipping or overwriting data,
clients are expected to use timestamp-driven coordination features such
as **X-Last-Modified** and **X-If-Unmodified-Since**.

The server guarantees a strictly consistent and monotonically-increasing
view of time within a single collection.  Every BSO has a last-modified
timestamp to indicate when it was last written, and the collection itself
has a last-modified timestamp to indicate when any BSO was last added,
deleted or changed.

Conceptually, each write request will perform the following operations as
an atomic unit:

  * Take the current timestamp on the server; call this timestamp `Tw`.
  * Check that `Tw` is less than or equal to the last-modified time of the
    target collection; if not then a **409 Conflict** response is generated.
  * Create any new BSOs as specified by the request, setting
    their last-modified timestamp to `Tw`.
  * Modify any existing BSOs as specified by the request, setting
    their last-modified timestamp to `Tw`.
  * Delete any BSOs as specified by the request.
  * Set the last-modified time of the collection to `Tw`.
  * Generate a **201** or **204** response with the **X-Last-Modified** and
    **X-Timestamp** headers set to `Tw`.

Thus, while write requests from different clients may be processed concurrently
by the server, they will appear to the clients to have occurred sequentially,
instantaneously and atomically.

To avoid having the server transmit data that has not changed since the last
request, clients should set the **X-If-Modified-Since** header and/or the
**newer** parameter to the last known value of **X-Last-Modified** on the
target resource.

To avoid overwriting changes made by others, clients should set the
**X-If-Unmodified-Since** header to the last known value of
**X-Last-Modified** on the target resource.


Examples
========

Example: polling for changes to a BSO
-------------------------------------

To efficiently check for changes to an individual BSO, use
**GET /storage/<collection>/<id>** with the **X-If-Modified-Since** header
set to the last known value of **X-Last-Modified** for that item.
This will return the updated item if it has been changed since the last
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
known value of **X-Last-Modified** for that collection.  This will return
only the BSOs that have been added or changed since the last request::

    last_modified = 0
    while True:
        r = server.get("/collection?newer=" + last_modified)
        for item in r.json_body["items"]:
            print "MODIFIED ITEM: ", item
        last_modified = r.headers["X-Last-Modified"]


Example: safely updating items in a collection
----------------------------------------------

To update items in a collection without overwriting any changes made by other
clients, use **POST /storage/<collection>** with the **X-If-Unmodified-Since**
header set to the last known value of **X-Last-Modified** for that collection.
If other clients have made changes to the collection since the last request,
the write will fail with a **412 Precondition Failed** response::

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

To guard against other clients making concurrent changes to the collection,
this technique should always be combined with the **X-If-Unmodified-Since**
header as shown below::

    r = server.get("/collection?limit=100")
    print "GOT ITEMS: ", r.json_body["items"]

    last_modified = r.headers["X-Last-Modified"]
    next_offset = r.headers.get("X-Next-Offset")

    while next_offset:
        headers = {"X-If-Unmodified-Since": last_modified}
        r = server.get("/collection?limit=100&offset=" + next_offset, headers)

        if r.status == 412:
            print "COLLECTION WAS MODIFIED WHILE READING ITEMS"
            break

        print "GOT ITEMS: ", r.json_body["items"]
        next_offset = r.headers.get("X-Next-Offset")


Changes from v1.1
=================

The following is a summary of protocol changes from :ref:`server_storage_api_11`:

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

* The *X-Last-Modified* header has been added, to provide clients with a more
  robust conflict-detection mechanism than the *X-Timestamp* header.

* The **POST /storage/collection** request no longer returns **modified** as
  part of its output, since this is available in the *X-Last-Modified* header.

* Successful **PUT** requests now give a **201 Created** or **204 No Content**
  response, rather than redundantly returning the value of *X-Last-Modified* in
  the response body.

* Successful **DELETE** requests now give a **204 No Content** response,
  response, rather than redundantly returning the value of *X-Last-Modified* in
  the response body.

* The **application/whoisi** output format has been removed.

* The **index_above** and **index_below** parameters have been removed.

* The **offset** parameter is now a server-generated value used to page
  through a set of results.  Clients must not attempt to create their
  own values for this parameter.

* The *X-If-Modified-Since* header has been added and can be used on all
  GET requests.

* The *X-If-Unmodified-Since* header can be used on GET requests to collections
  and items.

* The previously-undocumented *X-Weave-Quota-Remaining* header has been
  documented, after removing the "Weave" prefix.

* The *X-Weave-Records* header has been renamed to *X-Num-Records*.

* The *X-Weave-Alert* header has been removed.

* The *X-Confirm-Delete* header has been removed.

* The following response codes are explicitly mentioned: 201, 204, 304, 405,
  409, 412, 413.

* Various details of how Firefox Sync is implemented are no longer emphasized,
  since the protocol is being opened up for other applications.

