.. _tokenserver:

============
Token Server
============

Goal of the Service
===================

**Please Note**: BrowserID has been removed from Mozilla Accounts, and
therefore has also been removed from later versions of Tokenserver. Discussion
of BrowserID presented here is for historic purposes only.

So here's the challenge we face. Current login for sync looks like this:

1. provide username and password
2. we log into ldap with that username and password and grab your sync node
3. we check the sync node against the url you've accessed, and use that to
   configure where your data is stored.

This solution works great for centralized login. It's fast, has a minimum
number of steps, and caches the data centrally. The system that does
node-assignment is lightweight, since the client and server both cache the
result, and has support for multiple applications with the /node/<app> API
protocol.

However, this breaks horribly when we don't have centralized login. Adding
support for FxA Authentication to the SyncStorage protocol means that we're now
there.
We're going to get valid requests from users who don't have an account in FxA.
We won't even know, when they make a first request, if the node-assignment
server has ever heard of them.

So, we have a bunch of requirements for the system. Not all of them are
must-haves, but they're all things we need to think about trading off in
whatever system gets designed:

- need to support multiple services (not necessarily centrally)
- need to be able to assign users to different machines as a service
  scales out, or somehow distribute them
- need to consistently send a user back to the same server once they've
  been assigned
- need to give operations some level of control over how users are allocated
- need to provide some recourse if a particular node dies
- need to handle exhaustion attacks. For example, I could set up an primary that
  just auto-approved any username, then loop through users until all nodes were
  full.
- need support for future developments like bucketed assignment
- needs to be a system that scales infinitely.

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
  For example it could be 30 minutes for Sync and 2 hours for bipostal.

- The Login Server keeps a white list of domains for BID verifications


Documentation content
=====================

.. toctree::
   :maxdepth: 2

   apis
   user-flow
   history

Resources
=========

- Server: https://github.com/mozilla-services/tokenserver
