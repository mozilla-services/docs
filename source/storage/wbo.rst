.. _storage_wbo:

==================
Weave Basic Object
==================

All records send to and received from the server are JSON blobs. 

Format
======

The following describes the JS-object represented by the JSON-string record:

=========  ==========  ======================================================
Key        Type        Description
=========  ==========  ======================================================
id         string      Record identifier. This **should** be exactly 12
                       characters from the base64url alphabet. While this
                       isn't enforced by the server, the Firefox client
                       expects this in most cases.
modified   number      Time when this record was last changed. Set by the
                       server.
sortindex  number      Relative importance of this record.
payload    string      String with data. Usually a JSON-string.
ttl        integer     The number of seconds to keep this record. After that
           (optional)  time, this item will not be returned and eventually
                       be deleted from the server.
=========  ==========  ======================================================

Example
=======

::

    {
      "id":"-F_Szdjg3GzY",
      "modified":1278109839.96,
      "sortindex":140,
      "payload":"{\"ciphertext\":\"e2zLWJYX\/iTw3WXQqffo00kuuut0Sk3G7erqXD8c65S5QfB85rqolFAU0r72GbbLkS7ZBpcpmAvX6LckEBBhQPyMt7lJzfwCUxIN\/uCTpwlf9MvioGX0d4uk3G8h1YZvrEs45hWngKKf7dTqOxaJ6kGp507A6AvCUVuT7jzG70fvTCIFyemV+Rn80rgzHHDlVy4FYti6tDkmhx8t6OMnH9o\/ax\/3B2cM+6J2Frj6Q83OEW\/QBC8Q6\/XHgtJJlFi6fKWrG+XtFxS2\/AazbkAMWgPfhZvIGVwkM2HeZtiuRLM=\",\"IV\":\"GluQHjEH65G0gPk\/d\/OGmg==\",\"hmac\":\"c550f20a784cab566f8b2223e546c3abbd52e2709e74e4e9902faad8611aa289\"}"
    }
