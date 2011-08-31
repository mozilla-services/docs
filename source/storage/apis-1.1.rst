.. _server_storage_api_11:

================
Storage API v1.1
================

The Storage server provides web services that can be used to store and 
retrieve **Weave Basic Objects** or **WBOs** organized into **collections**.


Weave Basic Object
==================

A **WBO** is the generic wrapper around all items passed into and out 
of the storage server. 

A **WBO** has the following fields:

+---------------+-----------+------------+---------------------------------------------------------------+
| Parameter     | Default   | Type/Max   |  Description                                                  | 
+===============+===========+============+===============================================================+
| id            | required  |  string    | An identifying string. For a user, the id must be unique for  |
|               |           |  64        | a WBO within a collection, though objects in different        |
|               |           |            | collections may have the same ID.                             |
|               |           |            | Ids should be ASCII and not contain commas.                   |
+---------------+-----------+------------+---------------------------------------------------------------+
| parentid      | none      | string     | The id of a parent object in the same collection. This allows |
|               |           | 64         | for the creation of hierarchical structures (such as folders).|
|               |           |            | [1]_                                                          |
+---------------+-----------+------------+---------------------------------------------------------------+
| predecessorid | none      | string     | The id of a predecessor in the same collection. This allows   |
|               |           | 64         | for the creation of linked-list-esque structures. [1]_        |
+---------------+-----------+------------+---------------------------------------------------------------+
| modified      | time      | float      | The last-modified date, in seconds since 01/01/1970 [2]_ [3]_ |
|               | submitted | 2 decimal  |                                                               |
|               |           | places     |                                                               |
+---------------+-----------+------------+---------------------------------------------------------------+
| sortindex     | none      | integer    | An integer indicting the relative importance of this item in  |
|               |           |            | the collection.                                               |
+---------------+-----------+------------+---------------------------------------------------------------+
| payload       | none      | string     | A string containing a JSON structure encapsulating the data   | 
|               |           | 256k       | of the record. This structure is defined separately for each  |
|               |           |            | WBO type. Parts of the structure may be encrypted, in which   |
|               |           |            | case the structure should also specify a record for           |
|               |           |            | decryption.                                                   |
+---------------+-----------+------------+---------------------------------------------------------------+
| payload_size  | none      | integer    | Size of the payload. [3]_                                     |
+---------------+-----------+------------+---------------------------------------------------------------+
| ttl           | none      | integer    | The number of seconds to keep this record. After that time,   |
|               |           |            | this item will not be returned.                               |
+---------------+-----------+------------+---------------------------------------------------------------+


.. [1] This is deprecated and likely going away in future versions
.. [2] See ecma-262: http://www.ecma-international.org/publications/standards/Ecma-262.htm
.. [3] Set automatically by the server


Weave Basic Objects and all data passed into the server should be utf-8 encoded.

Sample::

    {
    "id": "B1549145-55CB-4A6B-9526-70D370821BB5",
    "parentid": "88C3865F-05A6-4E5C-8867-0FAC9AE264FC",
    "modified": "2454725.98",
    "payload": "{\"encryption\":\"http://server/prefix/version/user/crypto-meta/B1549145-55CB-4A6B-9526-70D370821BB5\", \"data\": \"a89sdmawo58aqlva.8vj2w9fmq2af8vamva98fgqamff...\"}"
    }


Collections
===========

Each WBO is assigned to a collection with other related WBOs. Collection names
may only contain alphanumeric characters, period, underscore and hyphen.
Default Mozilla collections are:

* bookmarks
* history
* forms
* prefs
* tabs
* passwords

Additionally, the following collections are supported for internal storage client
use:

* clients
* crypto
* keys
* meta

URL semantics
=============

Storag URLs follow, for the most part, REST semantics. Request and response
bodies are all JSON-encoded.

The URL for Weave Storage requests is structured as follows::

    https://<server name>/<api pathname>/<version>/<username>/<further instruction>

+---------------------+---------------------------+-------------------------------------------------------------------+
| Component           | Mozilla Default           | Description                                                       |
+=====================+===========================+===================================================================+
| server name         | defined by user account   | the hostname of the server                                        |
+---------------------+---------------------------+-------------------------------------------------------------------+
| pathname            | (none)                    | the prefix associated with the service on the box                 |
+---------------------+---------------------------+-------------------------------------------------------------------+
| version             | 1.1                       | The API version.                                                  |
+---------------------+---------------------------+-------------------------------------------------------------------+
| username            | (none)                    | the name of the object (user) to be manipulated                   |
+---------------------+---------------------------+-------------------------------------------------------------------+
| further instruction | (none)                    | The additional function information as defined in the paths below |
+---------------------+---------------------------+-------------------------------------------------------------------+

Certain functions use HTTP basic auth (over SSL, so as to maintain password
security). If the auth username does not match the username in the path, the
server will issue an Error Response

The User API has a set of Response Codes to cover errors in the
request or on the server side. The format of a successful response is defined
in the appropriate request method section. The User API has a set of
:ref:`respcodes` to cover errors in the request or on the server side.
The format of a successful response is defined in the appropriate request
method section.


APIs
====

**GET** **https://server/pathname/version/username/info/collections**

    Returns a hash of collections associated with the account, along with 
    the last modified timestamp for each collection.


**GET** **https://server/pathname/version/username/info/collection_usage**

    Returns a hash of collections associated with the account, along with 
    the data volume used for each (in K).


**GET** **https://server/pathname/version/username/info/collection_counts**

    Returns a hash of collections associated with the account, along with 
    the total number of items for each collection.


**GET** **https://server/pathname/version/username/info/quota**

    Returns a list containing the user's current usage and quota (in KB). 
    The second value will be null if no quota is defined.


**GET** **https://server/pathname/version/username/storage/collection**

    Returns a list of the WBO ids contained in a collection. 
    This request has additional optional parameters:

    - **ids**: returns the ids for objects in the collection that are in 
      the provided comma-separated list.

    - **predecessorid**: returns the ids for objects in the collection 
      that are directly preceded by the id given. Usually only returns 
      one result. [4]_

    - **parentid**: returns the ids for objects in the collection that 
      are the children of the parent id given. [4]_

    - **older**: returns only ids for objects in the collection that 
      have been last modified before the date given.

    - **newer**: returns only ids for objects in the collection that 
      have been last modified since the date given.

    - **full**: if defined, returns the full WBO, rather than just the id.

    - **index_above**: if defined, only returns items with a higher 
      sortindex than the value specified.

    - **index_below**: if defined, only returns items with a lower 
      sortindex than the value specified.

    - **limit**: sets the maximum number of ids that will be returned.

    - **offset**: skips the first n ids. For use with the limit 
      parameter (required) to paginate through a result set.

    - **sort**: sorts the output.

     - 'oldest' - Orders by modification date (oldest first)
     - 'newest' - Orders by modification date (newest first)
     - 'index' - Orders by the sortindex descending (highest weight first)



    Two alternate output formats are available for multiple record GET 
    requests. They are triggered by the presence of the appropriate 
    format in the **Accept** header (with *application/whoisi* taking 
    precedence):

    - **application/whoisi**: each record consists of a 32-bit integer, 
      defining the length of the record, followed by the json record for a 
      wbo 

    - **application/newlines**: each record is a separate json object on 
      its own line. Newlines in the body of the json object are replaced 
      by '\u000a' 



**GET** **https://server/pathname/version/username/storage/collection/id**

    Returns the WBO in the collection corresponding to the requested id


**PUT** **https://server/pathname/version/username/storage/collection/id**

    Adds the WBO defined in the request body to the collection. If the WBO 
    does not contain a payload, it will only update the provided metadata 
    fields on an already defined object.

    The server will return the timestamp associated with the modification.


**POST** **https://server/pathname/version/username/storage/collection**

    Takes an array of WBOs in the request body and iterates over them, 
    effectively doing a series of atomic PUTs with the same timestamp.

    Returns a hash of successful and unsuccessful saves, including 
    guidance as to possible errors::

        {"modified": 1233702554.25, 
         "success": ["{GXS58IDC}12", "{GXS58IDC}13", "{GXS58IDC}15",
                     "{GXS58IDC}16", "{GXS58IDC}18", "{GXS58IDC}19"],
         "failed": {"{GXS58IDC}11": ["invalid parentid"],
                    "{GXS58IDC}14": ["invalid parentid"],
                    "{GXS58IDC}17": ["invalid parentid"],
                    "{GXS58IDC}20":["invalid parentid"]}}


**DELETE** **https://server/pathname/version/username/storage/collection**

    Deletes the collection and all contents. Additional request parameters 
    may modify the selection of which items to delete:

    - **ids**: deletes the ids for objects in the collection that are in 
      the provided comma-separated list. 

    - **parentid**: only deletes objects in the collection that are the 
      children of the parent id given. [4]_

    - **older**: only deletes objects in the collection that have been 
      last modified before the date given. [4]_

    - **newer**: only deletes objects in the collection that have been 
      last modified since the date given. [4]_

    - **limit**: sets the maximum number of objects that will be deleted. [4]_

    - **offset**: skips the first n objects in the defined set. Must be 
      used with the limit parameter. [5]_ 

    - **sort** : sorts before deleting [4]_

     - 'oldest' - Orders by modification date (oldest first)
     - 'newest' - Orders by modification date (newest first)
     - 'index' - Orders by the sortindex (ordered lists)
     - 'depthindex' - Orders by depth, then by sortindex (ordered trees)


**DELETE** **https://server/pathname/version/username/storage/collection/id**

    Deletes the WBO at the location given


**DELETE** **https://server/pathname/version/username/storage**

    Deletes all records for the user. Will return a precondition error 
    unless an *X-Confirm-Delete* header is included.

    All delete requests return the timestamp of the action. 


.. [4] Deprecated in 1.1
.. [5] This function is not currently operational in the mysql implementation

Headers
=======

**Retry-After**

    When sent together with an HTTP 503 status code, it signifies that the
    server is undergoing maintenance. The client should not attempt another
    sync for the number of seconds specified in the header value.


**X-Weave-Backoff**

    Indicates that the server is under heavy load  and the client should not
    trigger another sync for the number of seconds specified in the header
    value (usually 1800).


**X-If-Unmodified-Since**

    On any write transaction (PUT, POST, DELETE), this header may be added 
    to the request, set to a timestamp. If the collection to be acted 
    on has been modified since the timestamp given, the request will fail.


**X-Weave-Alert**

    This header may be sent back from any transaction, and contains potential 
    warning messages, information, or other alerts. The contents are 
    intended to be human-readable.
    

**X-Weave-Timestamp**

    This header will be sent back with all requests, indicating the current 
    timestamp on the server. If the request was a PUT or POST, this will 
    also be the modification date of any WBOs submitted or modified.


**X-Weave-Records**

    If supported by the DB, this header will return the number of records 
    total in the request body of any multiple-record GET request. 

HTTP status codes
=================

**200**

    The request was processed successfully.


**400**

    The request itself or the data supplied along with the request is invalid.
    The response contains a numeric code indicating the reason for why the
    request was rejected. See :ref:`respcodes` for a list of valid response
    codes.


**401**

    The username and password are invalid on this node. This may either be
    caused by a node reassignment or by a password change. The client should
    check with the auth server whether the user's node has changed. If it has
    changed, the current sync is to be aborted and should be retried against
    the new node. If the node hasn't changed, the user's password was changed.


**404**

    The requested resource could not be found. This may be return for **GET**
    and **DELETE** requests for non-existent records and empty collections.


**503**

    Indicates, in conjuction with the **Retry-After** header, that the server
    is undergoing maintenance. The client should not attempt another sync for
    the number of seconds specified in the header value. The response body
    may contain JSON string describing the server's status or error.
