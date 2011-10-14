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

::

    // - lock
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
    // - update engine last modified timestamps
    // - sync clients engine
    //   - clients engine always fetches all records
    // - process reset/wipe requests in 'firstSync' preference
    // - process any commands, including the 'wipeClient' command
    // - infer enabled engines from meta/global
    // - sync engines
    //   - only stop if 401 is encountered
    // - if meta/global has changed, reupload it
    // - unlock
