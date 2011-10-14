.. _sync_metaglobal:

==================
meta/global Record
==================

The meta/global record is a special record on the Sync Server that contains
general metadata to describe the state of data on the Sync Server. This state includes things like the global storage version and the set of
available engines/collections on the server.

The meta/global record is different from other records in that it is not
encrypted. Like all other records, it is a JSON string. It has the following fields:

- **storageVersion**: Integer version of the storage format used. Clients
  look at this version to ensure they can read data on the server. Clients
  that don't understand a seen version will typically abort, assuming that
  a Sync client upgrade is available.
- **syncID**: Opaque string that changes when drastic changes happen to the
  overall data. Change of this string can cause clients to drop cached data.
  The Firefox client uses 12 randomly generated base64url characters, much
  like for WBO IDs.
- **engines**: A hash with fields of engine names and values of objects that
  contain *version* and *syncID* fields, which behave like the *storageVersion*
  and *syncID* fields on this record, but on a per-engine level.

Example
-------

::

    {
      "syncID":"7vO3Zcdu6V4I",
      "storageVersion":5,
      "engines":{
        "clients":   {"version":1,"syncID":"Re1DKzUQE2jt"},
        "bookmarks": {"version":2,"syncID":"ApPN6v8VY42s"},
        "forms":     {"version":1,"syncID":"lLnCTaQM3SPR"},
        "tabs":      {"version":1,"syncID":"G1nU87H-7jdl"},
        "history":   {"version":1,"syncID":"9Tvy_Vlb44b2"},
        "passwords": {"version":1,"syncID":"yfBi2v7PpFO2"},
        "prefs":     {"version":2,"syncID":"8eONx16GXAlp"}
      }
    }
