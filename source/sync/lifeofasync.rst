.. _sync_lifeofasync:

==================
The life of a sync
==================

XXX TODO WRITEME

::

  o/` But if I share my secret
      You're gonna have to keep it
      Nobody else can see this

      And it goes like this:     o/`

Verify set up
=============

::

    // - figure out whether we have everything to sync
    //   - do we have all credentials?
    //   - do we have a firstSync?
    //   - are we online?
    //   - have we met backoff?
    //   - master password unlocked?
    // - do we have clusterURL?
    //   - if we don't, fetch it.
    //   - if we can't, abort sync
    // - fetch info/collections
    //   - also serves as verifying credentials, abort if unsuccesful
    //   - use ?v=<version> once a day (does we still need that for metrics?)
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
============

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
=================

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
===============================

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
