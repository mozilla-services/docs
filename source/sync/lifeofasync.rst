.. _sync_lifeofasync:

==================
The Life of a Sync
==================

This document essentially describes how to write a Sync client.

Because the Sync server is essentially a dumb storage bucket, most of the
complexity of Sync is the responsibility of the client. This is good for users'
data security. It is bad for people implementing Sync clients. This document
will hopefully alleviate common issues and answer common questions.

Strictly speaking, information in this document applies only to a specific
version of the Sync server storage format. In practice, client behavior is
similar across storage versions. And, since we wish for clients to support
the latest/greatest versions of everything, this document will target that.

Initial Client Configuration
============================

The process of performing a sync starts with configuring a fresh client. Before
you can even think about performing a sync, the client needs to possess key
pieces of information. These include:

* The URL of the Sync server.
* Credentials used to access the Sync server.

Depending on the versions of the Sync server and global storage version, you
may also need a Sync Key or similar private key which is used to access
encrypted data on an existing account.

Obtaining these pieces of information is highly dependent on the server
instance you will be communicating with, the client in use, and whether you are
creating a new account or joining an existing one.

How Mozilla and Firefox Does It
-------------------------------

For reference, this section describes how Mozilla and Firefox handle initial
client configuration.

Inside Firefox there exists a UI to *Set up Firefox Sync*. The user chooses
whether she is setting up a new account or whether she wants to connect to an
existing account.

For completely new accounts, the user is presented with a standard sign-up
form. The user enters her email address and selects a password. Behind the
scenes Firefox is talking to a user provisioning service and the account is
created there and a Sync server is assigned (Mozilla exposes many different
Sync server instances to the Internet and the client connects directly to just
one of them). At this time, a new Sync Key encryption key is generated and
stored in Firefox's credential manager (possibly protected behind a master
password).

If the user selects an existing account, the user is presented 12 random
characters. These are entered on another device and the two devices
effectively pair and share the login credentials, Sync Key, and server info.
This is done with J-PAKE, so the data is secure as it is transported between
devices. Even the intermediary agent bridging the connection between the two
devices can't decrypt the data inside.

Performing a Sync
=================

Settings and State Pre-check
----------------------------

To perform a sync, a client will first need to perform some basic checks:

- Do we have all necessary credentials?
  - Storage server HTTP credentials
  - Sync Key
- Are we online (do we have network connectivity)
- Are we prohibited from syncing due to result from a previous sync?
  - The server may have issued a backoff telling us to slow down, etc

If these are all satisfied, the client can move on to the next phase.

Inspect and Reconcile Client and Server State
---------------------------------------------

The initial requests performed on the Sync server serve to inspect, verify,
and reconcile high-level state between the client and server.

Fetch info/collections
^^^^^^^^^^^^^^^^^^^^^^

The first request to the Sync server should be a GET on the info/collections
URI. This is a utility API provided by the storage service that reveals which
collections exist on the server and when they were last modified.

If the client has synced before, it should issue a conditional HTTP request by
adding an *X-If-Modified-Since* header to the request. If the server responds
with a 304, it means that no modifications have been made since the last sync.
If the client has no new data to upload (perhaps it was just checking to see if
there was any new data it needed to download), it can stop the sync right now:
there is nothing more for it to do!

The info/collections request also serves as a means to verify that the local
credentials can connect with the server. If the server issues a 401 or 404
response, the client should interpret this as credentials failure. The next
steps is this case are highly dependent on how the Sync server is configured.
If using some kind of cached credentials (such as a token), the client may want
to automatically try to fetch new credentials and try again.

Assuming you have a response from info/collections, you'll need to process that
response and possibly take action. If you received a 304 and have data to
upload, you can potentially skip processing if you have all the required values
cached locally.

.. graphviz::

  digraph fetch_info_collections {
    PREPARE_REQUEST [label="Prepare HTTP Request"];
    HAVE_SYNCED_BEFORE [label="Have Synced Before?" shape="diamond"];
    ADD_IMS [label="Add X-If-Modified-Since Header"];
    PERFORM_REQUEST [label="Perform HTTP Request"];
    CHECK_RESPONSE [label="Check Response" shape="diamond"];
    HAVE_OUTGOING [label="Have Outgoing Changes?" shape="diamond"];
    REAUTHENTICATE [label="Reauthenticate" shape="Mdiamond"];
    END_SYNC [label="End Sync" shape="Mdiamond"];
    NEXT_STEP [label="Next Step" shape="Mdiamond"];

    PREPARE_REQUEST -> HAVE_SYNCED_BEFORE;
    HAVE_SYNCED_BEFORE -> ADD_IMS [label="Yes"];
    HAVE_SYNCED_BEFORE -> PERFORM_REQUEST [label="No"];
    ADD_IMS -> PERFORM_REQUEST;
    PERFORM_REQUEST -> CHECK_RESPONSE [label="Wait for Response"];
    CHECK_RESPONSE -> HAVE_OUTGOING [label="304"];
    CHECK_RESPONSE -> REAUTHENTICATE [label="401, 403"];
    HAVE_OUTGOING -> END_SYNC [label="No"];
    HAVE_OUTGOING -> NEXT_STEP [label="Yes"];
  }

Validate meta/global
^^^^^^^^^^^^^^^^^^^^

The client needs to validate the meta/global record on every request. Upon
successful completion of the info/collections request, the following outcomes
are possible:

1. The *meta* collection does not exist.
2. The *meta* collection has been modified since the last sync.
3. The *meta* collection has not been modified since the last sync.

If the *meta* collection does not exist, the *global* record inside of it
cannot exist. This means no client has synced yet. If info/collections reveals
*any* collection exists, the client should issue a request to delete all data
from the server to ensure the server is in a fresh state. If there are no
collections on the server, you don't need to issue a delete.

Before we talk about uploading a new meta/global record, let's talk about
processing existing ones.

If the *meta* collection has not been modified since the last sync and we have
all of the data from a previous fetch of the meta/global cached locally
(scenario 3), the client doesn't need to do anything.

If the *meta* collection has been modified or if the client doesn't have a
cached copy of the metaglobal data, the client will need to fetch the
meta/global record. Simply issue a GET request to the appropriate URI and
decode the payload according to the rules for the storage version the client
is using.

If you can't decode the payload, that's bad and should never happen.
But, it is possible, so you need to handle it. One solution is to delete all
data from the server and upload a new record. However, data on the server could
be from a newer client this one just can't understand, so it shouldn't do this
lightly. The storage versions have been defined such that the decoding format
of the meta/global are backwards compatible with prior versions. So, if there
is an error decoding, there is almost certainly something wrong going on.

From the decoded payload, the client should first inspect the storage version
number. If the client supports this storage version, all is well. Carry on. If
not, the client has a few choices to make. If the version is older than what
the client supports, the client can upgrade the server's data to the new
version. These semantics are highly specific to the specific version change.
If the version is newer than what the client supports, the client should likely
interpret this as "there is a newer client out there - I'm too old and need to
upgrade." If clients see a new storage format, they should probably stop what
they are doing. Under no circumstances should clients attempt to modify data
belonging to a newer storage version. Instead, delete all data and perform a
fresh start (if this is really what you want to do).

**This section is incomplete. There is more that needs to be described. The
graph below is also incomplete.**

.. graphviz::

  digraph ensure_metaglobal {
    CHECK_INFO_COLLECTIONS [label="Check info/collections" shape="diamond"]
    CHECK_ANY_COLLECTIONS [label="Any Collections Exist?" shape="diamond"]

    DELETE_ALL [label="Delete all Server Collections"];
    CHECK_DELETE_ALL_RESPONSE [label="Process Response" shape="diamond"];

    CHECK_META_MODIFIED [label="Modified Since Last Sync?" shape="diamond"];

    FRESH_START [label="Fresh Start"];
    START_NEW_SYNC [label="Start New Sync" shape="Mdiamond"];

    CHECK_INFO_COLLECTIONS -> CHECK_ANY_COLLECTIONS [label="No 'meta' collection"];

    CHECK_ANY_COLLECTIONS -> DELETE_ALL [label="Yes"];
    CHECK_ANY_COLLECTIONS -> FRESH_START [label="No"];
    DELETE_ALL -> CHECK_DELETE_ALL_RESPONSE [label="Wait for Response"];

    CHECK_DELETE_ALL_RESPONSE -> FRESH_START [label="204 No Content"];
    CHECK_DELETE_ALL_RESPONSE -> START_NEW_SYNC [label="401, 403"];

    CHECK_ANY_COLLECTIONS -> CHECK_META_MODIFIED [label="Have 'meta' collection"];

    CHECK_META_MODIFIED -> TODO;
  }

Validate crypto/keys
^^^^^^^^^^^^^^^^^^^^

**TODO**

OLD CONTENT
===========

Don't read below this. It is old and needs to be formalized.

Verify set up
-------------

::

    // - fetch keys if 'crypto' timestamp differs from local one
    //   - if it's non-existent, goto fresh start.
    //   - decrypt keys with Sync Key, abort if HMAC verification fails.
    // - fetch meta/global if 'meta' timestamp differs from local one
    //   - if it's non-existent, goto fresh start.
    //   - check for storage version. if server data outdated, goto fresh start.
    //     if client is outdated, abort with friendly error message.
    //   - if syncID mismatch, reset local timestamps, refetch keys
    // - if fresh start:
    //   - wipe server. all of it.
    //   - create + upload meta/global
    //   - generate + upload new keys

Perform sync
------------

::

    // - update engine last modified timestamps from info/collections record
    // - sync clients engine
    //   - clients engine always fetches all records
    // - process reset/wipe requests in 'firstSync' preference
    // - process any commands, including the 'wipeClient' command
    // - infer enabled engines from meta/global
    // - sync engines
    //   - only stop if 401 is encountered
    // - if meta/global has changed, reupload it

Syncing an engine
-----------------

::

    // TODO WRITEME

    // - meta/global
    //   - syncID
    //   - engine storage format
    // - fetch incoming records
         - GET .../storage/<collection>?newer=<last_sync_server_timestamp>&full=1
         - optional but recommended for streaming: Accept: application/newlines
         - deserialize and apply each record:
           - JSON parse WBO
           - JSON parse payload
           - verify HMAC
           - decrypt ciphertext witH IV
           - JSON parse cleartext
           - apply to local storage
             - TODO deduping
        - fetch outgoing records (e.g. via last sync local timestamp,
          or from list of tracked items, ...)
          - serialize each record
            - assemble cleartext record and JSON stringify
            - assemble payload and JSON stringify
              - generate random IV and encrypt cleartext to ciphertext
              - compute HMAC
            - assemble WBO and JSON stringify
            - upload in batches of 100 or 1 MB, whichever comes first
              - POST .../storage/<collection>
                [{record}, {record}, ...]
              - process repsonse body

High-level implementation notes
-------------------------------

::

   // TODO WRITEME
   // - Repository
   //   - fetchSince()
   //     - for batching: guidsSince() + fetch() (fetches by GUIDs)
   //   - store()
   //   - wipe()
   // - Middleware
   //   - wraps a repository e.g. to encrypt/decrypt records as they
   //     pass through
   // - Synchronizer
   //   - synchronizes two repositories
