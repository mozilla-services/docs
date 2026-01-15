==============================
DEPRECATION NOTE
==============================
This repo has been archived and the documentation is no longer maintained.
Sync and Tokenserver docs and code are in the `syncstorage-rs` GitHub repo.
You can find the repo for this service `here <https://github.com/mozilla-services/syncstorage-rs>`_ and the maintained documentation `here <https://mozilla-services.github.io/syncstorage-rs/>`_.

========
Glossary
========

.. glossary::
   :sorted:

   Service
      A service Mozilla provides, like **Sync**.

   Login Server
      Used to authenticate user, returns tokens that can be used
      to authenticate to our services.

   Node
      An URL that identifies a service, like http://phx345

   Service Node
      a server that contains the service, and can be mapped to several
      Nodes (URLs)

   Node Assignment Server
      A service that can attribute to a user a node.

   User DB
      A database that keeps the user/node relation

   Cluster
      Group of webheads and storage devices that make up a set of Service
      Nodes.

   HKDF
      HMAC-based Key Derivation Function, a method for deriving multiple
      secret keys from a single master secret.

      See https://tools.ietf.org/html/rfc5869

   Hawk Auth
      An HTTP authentication method using a message authentication code
      (MAC) algorithm to provide cryptographic verification of portions of
      HTTP requests.

      See https://github.com/hueniverse/hawk/

   Auth Token
      Used to identify the user after starting a session.  Contains the
      user application id and the expiration date.

   Master Secret
      A secret shared between Login Server and Service Node.
      Never used directly, only for deriving other secrets.

   Signing Secret
      Derived from the master secret, used to sign the auth token.

   Token Secret
      Derived from the master secret and auth token, used as **secret**.
      This is the only secret shared with the client and is different for each
      auth token.

   Generation Number
      An integer that may be included in an identity certificate.
      The issuing server increases this value whenever the user changes
      their password.  By rejecting assertions with a generation
      number lower than the previously-seen maximum for that user, the
      Login Server can reject assertions generated using an old password.

   Weave
      The original code name for the Firefox Sync service and project.
