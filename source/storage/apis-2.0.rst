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
|               |           |            | BSO ids may contain any alphanumeric character as well as     |
|               |           |            | the period, underscore and hyphen.                            |
|               |           |            |                                                               |
|               |           |            | **Note:**  Applications may impose more stringent requirements|
|               |           |            | on BSO ids.  For example, the Firefox Sync client expects ids |
|               |           |            | to be exactly 12 characters from the base64url alphabet.      |
+---------------+-----------+------------+---------------------------------------------------------------+
| modified      | time      | integer    | The last-modified date, in milliseconds since UNIX epoch      |
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
may only contain alphanumeric characters, period, underscore and hyphen.

Collections are created implicitly on demand, when storing a BSO in them for
the first time.


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

**GET https://<endpoint-url>/info/collections**

    Returns an object mapping collection names associated with the account to
    the last modified timestamp for each collection.

    Possible HTTP status codes:

    - **304 Not Modified:**  no collections have been modified or deleted
      since the timestamp in the *X-If-Modified-Since* header.


**GET** **https://<endpoint-url>/info/quota**

    Returns an object giving details of the user's current usage and
    quota.  It will have the following keys:

    - **usage**:  the user's total current usage in KB.
    - **quota**:  the user's total quota (or null if quotas are not in use)

    Note that usage numbers may be approximate.

    Possible HTTP status codes:

    - **304 Not Modified:**  no collections have been modified or deleted
      since the timestamp in the *X-If-Modified-Since* header.


**GET** **https://<endpoint-url>/info/collection_usage**

    Returns an object mapping collection names associated with the account to
    the data volume used for each collection (in KB).

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

    Returns a list of the BSOs contained in a collection.  By default only
    the BSO ids are returned, but full objects can be requested using the
    **full** parameter.

    This request has additional optional parameters:

    - **ids**: a comma-separated list of ids. Only objects whose id is in this
      list will be returned.

    - **older**: a timestamp in milliseconds. Only objects that were last
      modified before this time will be returned.

    - **newer**: a timestamp in milliseconds. Only objects that were last
      modified after this time will be returned.

    - **full**: any value.  If provided then the response will be a list of
      full BSO objects rather than a list of ids.

    - **index_above**: an integer. Only objects whose sortindex is higher than
      this value will be returned.

    - **index_below**: an integer. Only objects whose sortindex is lower than
      this value will be returned.

    - **limit**: an integer. At most that many objects will be returned.

    - **offset**: an integer.  Excludes that many objects from the start of
      the output.  This is desgined for pagination of results and must be used
      together with the **limit** parameter.

    - **sort**: sorts the output:
       - 'oldest' - orders by modification date (oldest first)
       - 'newest' - orders by modification date (newest first)
       - 'index' - orders by the sortindex descending (highest weight first)

    The response will include an *X-Num-Records* header indicating the
    total number of records to expect in the body.

    Two output formats are available for multiple record GET requests.
    They are triggered by the presence of the appropriate format in the
    *Accept* request header and are prioritized in the order listed below:

    - **application/json**: the output is a JSON list containing the
      requested records, as either string ids or full JSON objects.
    - **application/newlines**: the output contains each record on a separate
      line, as either a string id or a full JSON object. Any newlines in each
      record are replaced by '\\u000a'.

    Possible HTTP status codes:

    - **304 Not Modified:**  no objects in the collection have been modified
      since the timestamp in the *X-If-Modified-Since* header.
    - **404 Not Found:**  the user has no such collection.


**GET** **https://<endpoint-url>/storage/<collection>/<id>**

    Returns the BSO in the collection corresponding to the requested id

    Possible HTTP error responses:

    - **304 Not Modified:**  the object has not been modified since the
      timestamp in the *X-If-Modified-Since* header.
    - **404 Not Found:**  the user has no such collection, or it contains
      no such object.


**PUT** **https://<endpoint-url>/storage/<collection>/<id>**

    Adds the BSO defined in the request body to the collection. If the BSO
    does not contain a payload, it will only update the provided metadata
    fields on an already defined object.

    This request may include the *X-If-Unmodified-Since* header to avoid
    overwriting the data if it has been changed since the client fetched it.

    Successful requests will receive a **201 Created** response if a new
    BSO is created, or a **204 No Content** response if an existing BSO
    is updated  The response will include an *X-Timestamp* header giving
    the new modification time of the object.

    Note that the server may impose a limit on the amount of data submitted
    for storage in a single BSO.

    Possible HTTP error responses:

    - **412 Precondition Failed:**  the object has been modified since the
      timestamp in the *X-If-Unmodified-Since* header.
    - **413 Request Entity Too Large:**  the object is larger than the
      server is willing to store.


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
      on its own line. Newlines in the body of the BSO object are replaced
      by '\\u000a'.

    Note that the server may impose a limit on the total amount of data
    included in the request, and/or may decline to process more than a certain
    number of BSOs in a single request.

    Possible HTTP error responses:

    - **412 Precondition Failed:**  an object in the collection has been modified
      since the timestamp in the *X-If-Unmodified-Since* header.
    - **413 Request Entity Too Large:**  the request contains more data than the
      server is willing to process in a single batch.


**DELETE** **https://<endpoint-url>/storage/<collection>**

    Deletes the collection and all contents, returning the timestamp of
    the action. Successful requests will receive a **204 No Content** response.

    Additional request parameters may modify the selection of which items
    to delete:

    - **ids**: deletes the ids for objects in the collection that are in
      the provided comma-separated list.  A maximum of 100 ids may be
      provided.

    Possible HTTP error responses:

    - **400 Bad Request:**  too many ids where included in the query parameter.
    - **404 Not Found:**  the user has no such collection.
    - **412 Precondition Failed:**  an object in the collection has been
      modified since the timestamp in the *X-If-Unmodified-Since* header.


**DELETE** **https://<endpoint-url>/storage/<collection>/<id>**

    Deletes the BSO at the location given, returning the timestamp of the
    action. Successful requests will receive a **204 No Content** response.

    Possible HTTP error responses:

    - **404 Not Found:**  the user has no such collection, or it contains
      no such object.
    - **412 Precondition Failed:**  the object has been modified since the
      timestamp in the *X-If-Unmodified-Since* header.


Multi-Collection Interaction
----------------------------

APIs in this section are used for interaction with multiple collections.

**DELETE** **https://<endpoint-url>/storage**

    Deletes all records for the user.
    Successful requests will receive a **204 No Content** response.


Request Headers
===============

**X-If-Modified-Since**

    This header may be added to any GET request to avoid transmission of the
    resource body if it has not been modified since the client last fetched
    it.  It is similar to the standard If-Modified-Since header except the
    value is expressed in milliseconds.

    If the value of this header is not a valid integer, a **400 Bad Request**
    response will be returned.


**X-If-Unmodified-Since**

    On any write transaction (PUT, POST, DELETE), this header may be added
    to the request, set to a timestamp. If the collection to be acted
    on has been modified since the timestamp given, the request will fail.
    It is similar to the the standard If-Unmodified-Since header except the
    value is expressed in milliseconds.

    If the value of this header is not a valid integer, a **400 Bad Request**
    response will be returned.


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

    Clients should perform the minimum number of additional requests required
    to maintain consistency of their stored data, then not attempt any futher
    requests for the number of seconds specified in the header value.

**X-Timestamp**

    This header will be sent back with all responses, indicating the current
    timestamp on the server. If the request was a PUT or POST, this will
    also be the modification date of any BSOs modified by the request.

**X-Num-Records**

    This header may be sent back with multi-record responses, to indicate the
    total number of records included in the response.

**X-Quota-Remaining**

    This header may be returned in response to write requests, indicating
    the amount of storage space remaining for the user in KB.  It will
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


**412 Precondition Failed**

    For requests that include the *X-If-Unmodified-Since* header, this response
    code indicates that the resource was in fact modified.  The requested write
    operation will not have been performed.


**413 Request Entity Too Large**

    The body submitted with a write request (PUT, POST) was larger than the
    server is willing to accept.  For multi-record POST requests, the client
    should retry by sending the records in smaller batches.


**503 Service Unavailable**

    Indicates that the server is undergoing maintenance.  Such a response will
    include a  *Retry-After* header, and the client should not attempt
    another sync for the number of seconds specified in the header value.
    The response body may contain a JSON string describing the server's status
    or error.


Changes from v1.1
=================

The following is a summary of protocol changes from :ref:`server_storage_api_11`:

* The term "Weave" is no longer used anywhere in the protocol:
    * "Weave Basic Objects" have been renamed "Basic Storage Objects".
    * The "Weave" prefix has been removed from all custom headers.

* Authentication can now be performed using any HTTP Access Authentication
  method accepted by both client and server.  Mozilla-hosted services will
  accept only Sagrada Token Server authentication.

* URLs no longer contain a username component; the current user is taken from
  the authentication info and there is no way to refer to the stored data for
  another user.

* The WBO fields "parentid" and "predecessorid" have been removed, along with
  the corresponding query parameters on all requests.

* Timestamps are now reported in integer milliseconds rather than decimal seconds.

* The **GET /info/quota** request now returns an object with keys named "usage"
  and "quota", rather than just a list of numbers.

* The query parameters for **DELETE /storage/collection** have been removed.
  The only operations now supported are "delete these specific ids" and
  "delete the whole collection".

* The **POST /storage/collection** request now accepts application/newlines
  input in addition to application/json.

* The **POST /storage/collection** request no longer returns **modified** as
  part of its output, since this is available in the *X-Timestamp* header.

* Successful **PUT** requests now give a **201 Created** or **204 No Content**
  response, rather than redundantly returning the value of *X-Timestamp* in
  the response body.

* Successful **DELETE** requests now give a **204 No Content** response,
  response, rather than redundantly returning the value of *X-Timestamp* in
  the response body.

* The **application/whoisi** output format has been removed.

* The *X-If-Modified-Since* header has been added and can be used on all
  GET requests.

* The previously-undocumented *X-Weave-Quota-Remaining* header has been
  documented, after removing the "Weave" prefix.

* The *X-Weave-Records* header has been renamed to *X-Num-Records*.

* The *X-Weave-Alert* header has been removed.

* The *X-Confirm-Delete* header has been removed.

* The following response codes are explicitly mentioned: 304, 405, 412, 413.

* Various details of how Firefox Sync is implemented are no longer emphasized,
  since the protocol is being opened up for other applications.

