========
Glossary
========

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

   Mac Access Auth
      An HTTP authentication method using a message authentication code
      (MAC) algorithm to provide cryptographic verification of portions of
      HTTP requests.

      See https://tools.ietf.org/html/draft-ietf-oauth-v2-http-mac-01

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
