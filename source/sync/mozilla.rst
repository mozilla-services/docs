.. _sync_mozilla:

======================
Mozilla's Sync Service
======================

This document describes how Sync is deployed at Mozilla.

.. attention::

  This document is not complete. Consult the Services team for authoritative
  information.

Architecture
============

Mozilla's Sync service is comprised of the following services:

- :ref:`Storage Service 1.1 <server_storage_api_11>`
- :ref:`User Registration Service <reg>`
- :ref:`Secure-Registration Service <sreg>`
- :ref:`Easy Setup Key Exchange Service <ezsetup>`

Mozilla operates many instances of the Storage Service. We call these nodes.
Each node is independent from the others and has no knowledge that other
nodes exist.

When a new account is provisioned, the Registration Service assigns a user to
a node. The node is chosen based on which nodes have capacity, etc. After node
assignment, clients connect directly to that specific node. All Sync operations
are performed against that client's assigned Sync node.

The user registration service is hosted on https://auth.services.mozilla.com/.
If you download Firefox from Mozilla and set up Sync, this is where it will
connect by default.

Easy Setup Service
==================

Mozilla hosts an instance of the :ref:`Easy Setup <ezsetup>` service at
https://setup.services.mozilla.com/. When you pair two devices by entering
codes, they communicate through this service.

Crypto Record Semantics
=======================

:ref:`Storage Format 6<sync_storageformat6>` does not explicitly define
semantics for how **crypto records** are managed, leaving it up to the clients
to agree on behavior. This section documents the behavior in Mozilla clients.

Clients and Key Management
--------------------------

Sync clients can differ in their abilities to manage keys and their associated
crypto records on the server. There exist 2 tiers of clients:

- Tier 1 Client - Supports key generation and management.
- Tier 2 Client - Supports key consumption only.

Tier 1 clients are full Sync clients. They can provision accounts from empty
servers, reset server data, change keys around, etc. Tier 2 clients are simpler
clients that only support reading of keys (no writing).

The main reason why different tiers of clients exist is that cryptography,
security, and the management of keys is hard and that these problems should
be left to professionals. It is extremely easy for a client to introduce subtle
differences that could compromise the integrity of data security. By providing
a facility for clients that don't modify keys, we are reducing the surface area
on which a new client may error as well as decreasing the number of clients
which need to be validated for proper behavior.

Mozilla provides the following Tier 1 Clients:

- Firefox (on desktop)
- Firefox (on mobile - aka Fennec)

Tier 2 Client Behavior
^^^^^^^^^^^^^^^^^^^^^^

Tier 2 clients **never** perform updates to the *crypto* collection. Instead,
they read records and get the data they need. If the data they need is
unavailable (i.e. the record it wants isn't found), it gives up and tries again
later.

Tier 2 clients do support creating new collections on the server. When a Tier 2
client wishes to create a new collection, it will need to use a **Collection
Key Bundle** for that collection. Normally, a new **Collection Key Bundle**
would be created and uploaded. However, since Tier 2 clients must not modify
the *crypto* collection, they resort to other means.
