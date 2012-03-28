========
Glossary
========

Terms
=====

.. glossary::
   :sorted:

   Service
      A service Mozilla provides, like **Sync** or **Easy Setup**.

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

   Colo
      Physical datacenter, may contain multiple clusters

   HKDF
      HMAC-based Key Derivation Function, a method for deriving multiple
      secret keys from a single master secret.

      See https://tools.ietf.org/html/rfc5869

   Two-Legged OAuth
      An authentication scheme for HTTP requests, based on a HMAC
      signature over the request metadata.

      See http://tools.ietf.org/html/rfc5849#section-3

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


Assumptions
===========

- A Login Server detains the secret for all the Service Nodes for a given
  Service.

- Any given webhead in a cluster can receive calls to all service
  nodes in the cluster.

- The Login Server will support only BrowserID at first,
  but could support any authentication protocol in the future, as long as it
  can be done with a single call

- All servers are time-synced

- The expires value for a token is a fixed value per application.
  For example it could be 30mn for Sync and 2 hours for bipostal.

- The Login Server keeps a white list of domains for BID verifications

