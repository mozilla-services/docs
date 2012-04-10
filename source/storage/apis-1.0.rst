.. _server_storage_api_10:

================
Storage API v1.0
================

This document describes the Sync Server Storage API, version 1.0. It has been
replaced by :ref:`server_storage_api_11`.

Weave Basic Object (WBO)
========================

A Weave Basic Object is the generic wrapper around all items passed into and
out of the Weave server. The Weave Basic Object has the following fields:

+---------------+-----------+-----------+------------------------------------------------------+
| Parameter     | Default   | Max       | Description                                          |
+===============+===========+===========+======================================================+
| id            | required  | 64        | An identifying string. For a user, the id must be    |
|               |           |           | unique for a WBO within a collection, though         |
|               |           |           | objects in different collections may have the        |
|               |           |           | same ID. Ids should be ASCII and not contain commas. |
+---------------+-----------+-----------+------------------------------------------------------+
| parentid      | none      | 64        | The id of a parent object in the same collection.    |
|               |           |           | This allows for the creation of hierarchical         |
|               |           |           | structures (such as folders).                        |
+---------------+-----------+-----------+------------------------------------------------------+
| predecessorid | none      | 64        | The id of a predecessor in the same collection. This |
|               |           |           | allows for the creation of linked-list-esque         |
|               |           |           | structures.                                          |
+---------------+-----------+-----------+------------------------------------------------------+
| modified      | time      | float     | The last-modified date, in seconds since 1970-01-01  |
|               | submitted |           | (UNIX epoch time see [1]_). Set by the server.       |
|               |           | 2 decimal |                                                      |
|               |           | places    |                                                      |
+---------------+-----------+-----------+------------------------------------------------------+
| sortindex     | none      | 256K      | A string containing a JSON structure encapsulating   |
|               |           |           | the data of the record. This structure is defined    |
|               |           |           | separately for each WBO type. Parts of the structure |
|               |           |           | may be encrypted, in which case the structure should |
|               |           |           | also specify a record for decryption.                |
+---------------+-----------+-----------+------------------------------------------------------+
| payload       | none      | 256K      |                                                      |
+---------------+-----------+-----------+------------------------------------------------------+

.. [1] http://www.ecma-international.org/publications/standards/Ecma-262.htm ecma-262

Weave Basic Objects and all data passed into the Weave Server should be utf-8 encoded.

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
Collections supported at this time are:

* bookmarks
* history
* forms
* prefs
* tabs
* passwords

Additionally, the following collections are supported for internal Weave
client use:

* clients
* crypto
* keys
* meta

URL Semantics
=============

Weave URLs follow, for the most part, REST semantics. Request and response
bodies are all JSON-encoded.

The URL for Weave Storage requests is structured as follows::

    https://<server name>/<api pathname>/<version>/<username>/<further instruction>

===================  ================  ======================================
Component            Mozilla Default   Description
===================  ================  ======================================
server name          (defined by user  the hostname of the server
                     account node)
pathname             (none)            the prefix associated with the service
                                       on the box
version              1.0               The API version. May be integer or
                                       decimal
username             (none)            The name of the object (user) to be
                                       manipulated
further instruction  (none)            The additional function information as
                                       defined in the paths below
===================  ================  ======================================

Weave uses HTTP basic auth (over SSL, so as to maintain password security). If
the auth username does not match the username in the path, the server will
issue an `Error Response <respcodes>`_.

The Weave API has a set of  `Weave Response Codes <respcodes>`_ to cover errors
in the request or on the server side. The format of a successful response is
defined in the appropriate request method section.

GET
===

**https://*server*/*pathname*/*version*/*username*/info/collections**

    Returns a hash of collections associated with the account, along with the
    last modified timestamp for each collection.

**https://*server*/*pathname*/*version*/*username*/info/collection_counts**

    Returns a hash of collections associated with the account, along with the
    total number of items for each collection.

**https://*server*/*pathname*/*version*/*username*/info/quota**

    Returns a tuple containing the user's current usage (in K) and quota.

**https://*server*/*pathname*/*version*/*username*/storage/*collection***

    Returns a list of the WBO ids contained in a collection. This request has
    additional optional parameters:

    - **ids**: Returns the ids for objects in the collection that are in the
      provided comma-separated list.
    - **predecessorid**: Returns the ids for objects in the collection that
      are directly preceded by the id given. Usually only returns one result.
    - **parentid**: Returns the ids for objects in the collection that are the
      children of the parent id given.
    - **older**: Returns only ids for objects in the collection that have been
      last modified before the date given.
    - **newer**: Returns only ids for objects in the collection that have been
      last modified since the date given.
    - **full**: If defined, returns the full WBO, rather than just the id.
    - **index_above**: If defined, only returns items with a higher sortindex
      than the value specified.
    - **index_below**: If defined, only returns items with a lower sortindex
      than the value specified.
    - **limit**: Sets the maximum number of ids that will be returned.
    - **offset**: Skips the first n ids. For use with the limit parameter
      (required) to paginate through a result set.
    - **sort**:: sorts before getting
      - 'oldest' - Orders by modification date (oldest first)
      - 'newest' - Orders by modification date (newest first)
      - 'index' - Orders by the sortindex descending (highest weight first)


**https://*server*/*pathname*/*version*/*username*/storage/*collection*/*id***

    Returns the WBO in the collection corresponding to the requested id

Alternate Output Formats
========================

Two alternate output formats are available for multiple record GET requests.
They are triggered by the presence of the appropriate format in the Accept
header (with application/whoisi taking precedence)

* application/whoisi: each record consists of a 32-bit integer, defining the
  length of the record, followed by the json record for a wbo
* application/newlines: each record is a separate json object on its own line.
  Newlines in the body of the json object are replaced by '\u000a'

APIs
====

PUT
---

**https://*server*/*pathname*/*version*/*username*/storage/*collection*/*id***

Adds the WBO defined in the request body to the collection. If the WBO does
not contain a payload, it will only update the provided metadata fields on an
already defined object.

The server will return the timestamp associated with the modification.

POST
----

**https://*server*/*pathname*/*version*/*username*/storage/*collection***

Takes an array of WBOs in the request body and iterates over them,
effectively doing a series of atomic PUTs with the same timestamp.

Returns a hash of successful and unsuccessful saves, including guidance as to possible errors:


    {"modified":1233702554.25,"success":["{GXS58IDC}12","{GXS58IDC}13","{GXS58IDC}15","{GXS58IDC}16","{GXS58IDC}18","{GXS58IDC}19"],"failed":{"{GXS58IDC}11":["invalid parentid"],"{GXS58IDC}14":["invalid parentid"],"{GXS58IDC}17":["invalid parentid"],"{GXS58IDC}20":["invalid parentid"]}}

DELETE
------

**https://*server*/*pathname*/*version*/*username*/storage/*collection***

Deletes the collection and all contents. Additional request parameters may
modify the selection of which items to delete:

- **ids**: Deletes the ids for objects in the collection that are in the
  provided comma-separated list.
- **parentid**: Only deletes objects in the collection that are the children
  of the parent id given.
- **older**: Only deletes objects in the collection that have been last
  modified before the date given.
- **newer**: Only deletes objects in the collection that have been last
  modified since the date given.
- **limit**: Sets the maximum number of objects that will be deleted.
- **offset**: Skips the first n objects in the defined set. Must be used with
  the limit parameter. [This function is not currently operational in the mysql
  implementation]
- **sort**: Sorts items before deletion
  - 'oldest' - Orders by modification date (oldest first)
  - 'newest' - Orders by modification date (newest first)
  - 'index' - Orders by the sortindex (ordered lists)

**https://*server*/*pathname*/*version*/*username*/storage/*collection*/*id***

    Deletes the WBO at the location given

    All delete requests return the timestamp of the action.


**https://*server*/*pathname*/*version*/*username*/storage***

    Deletes all records for the user. Will return a precondition error unless
    an X-Confirm-Delete header is included.

    All delete requests return the timestamp of the action.

General Weave Headers
=====================

**X-Weave-Backoff**

    Indicates that the server is under heavy load or has suffered a failure
    and the client should not try again for the specified number of seconds
    (usually 1800)

**X-If-Unmodified-Since**

    On any write transaction (PUT, POST, DELETE), this header may be added to
    the request, set to a timestamp. If the collection to be acted on has been
    modified since the timestamp given, the request will fail.

**X-Weave-Alert**

    This header may be sent back from any transaction, and contains potential
    warning messages, information, or other alerts. The contents are intended
    to be human-readable.

**X-Weave-Timestamp**

    This header will be sent back with all requests, indicating the current
    timestamp on the server. If the request was a PUT or POST, this will also
    be the modification date of any WBOs submitted or modified.

**X-Weave-Records**
    If supported by the db, this header will return the number of records total
    in the request body of any multiple-record GET request.
