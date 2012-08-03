.. _server_aitc_lifeofanapp:

===============================
The Life of an App in the Cloud
===============================

This document describes how to write an "Apps in the Cloud" client, hereby
referred to as "AitC".

AitC uses a model that is very different from the Sync service, and is not
an engine for a new data type within Sync. Notably, it uses the token server
and BrowserID for authentication, and a different REST API to communicate with
the server.

The general model is that the server is the authoritative source for a list
of apps that a user has acquired (but not necessarily installed, a distinction
we will delve into later). Clients are expected to keep the server updated
with changes as soon as possible, in an effort to keep the server holding the
freshest data.

As a result, the reconciliation algorithm is pretty simple: a client replaces
its local list of apps to match that of the server, except if it has any local
changes that haven't been pushed to the server yet. In that case, the client
should not retrieve data from the server until it has pushed all pending
changes.

Initial Client Configuration
============================

There is no explicit account creation, the :ref:`token server<ezsetup>` will
implicitly create an account on the first request received for an email address
(or rather, a BrowserID assertion for a particular email address) it hasn't
seen before.

Therefore, the only piece of data a client needs before being able to perform
an AitC operation is a BrowserID assertion for the email address representing
the user.

Notes on obtaining an assertion
-------------------------------

This section describes the methods by which Firefox on the Desktop obtains
an assertion for the user's email address. The process may be different on
other platforms, but the basic idea is that we try to obtain an assertion
silently whenever possible, and only ask the user to explicitly login if they
are actively performing an AitC related operation and it makes sense to present
a login prompt.

On app startup, the client tries to obtain a BrowserID assertion silently for
an email address that can accurately represent the current user. The exact
mechanism may vary (in the future, we could use the "Sign in to the Browser"
feature, for example), but we currently implement a set of heuristics such as
trying to determine the email address the user last used to login to the
Mozilla app marketplace.

If an assertion is successfully obtained, the algorithm described in subsequent
sections will kick in.

We then set up listeners for a two URLs: the Mozilla app marketplace, and the
app "dashboard" (a web page displaying the current list of all the apps
acquired by the user). A listener for the app marketplace is simply an
optimization because we know that it is not possible for a user to install an
app from there without logging into BrowserID, which makes obtaining an
assertion (if one wasn't already obtained) easier.

Triggers
========

The client algorithm described later in this document should be executed
when one of the following occur:

1. App startup.

2. The user installs or uninstalls an app.

3. The user launches an app management app or webpage.

4. Periodically, at a reasonable time interval as dictated by the platform. In desktop Firefox, this value is 2 minutes when the user is actively using the browser, and 4 hours when the user is away (no keyboard/mouse activity in Firefox).

If an assertion could not be obtained silently, the third trigger presents
a good opportunity to prompt the user to login.

Algorithm
=========

TODO: Make this a flowchart.

1. Attempt to obtain a silent assertion for an email address that the client can be sure of representing the current user.

2. Setup listeners for the triggers listed above.

3. If an assertion is available, go to step 5.

4. If a trigger fires, attempt to obtain an assertion (silently or via a prompt, depending on the trigger) if one was not already obtained. Proceed to step 5 if an assertion was successfully generated. If not, wait for the next trigger.

  a) If the trigger was an app install or uninstall, store the change in a persistent local queue.

5. Obtain a token from the :ref:`token server<ezsetup>` (refer to that document for the exact procedure). Extract the endpoint from it, and ensure all subsequent network requests are made to that server (which should point to an AitC storage service), except when refreshing the token.

6. Check the persistent local queue for entries. For an app install and uninstall, a PUT request must be made. If you get a successful response code, remove the item from the queue; if not, add it back to the tail.

  a) Keep track of the number of failures (for both GET and PUT requests). If they exceed a certain threshold, the client may choose to remove the item causing the failure from the queue. Additionally, the client must backoff exponentially when continuous errors from the server are received.

  b) If a PUT results in a 401, obtain a new token from the token server before processing the next item in the queue.

7. If the queue is empty, perform a GET for all apps.

  a) If you receive a 401 response, refresh the token, just like for PUT.

8. Perform reconciliation and apply changes to the local app registry, if any.

9. Wait for the next trigger and go back to Step 4 when one is fired.

The exact semantics of the PUT and GET requests are specified in the
:ref:`API Docs<server_aitc_api_20>`.

Reconciliation
==============

Upon receiving an array of app objects as a result of a GET request, do the
following (keep in mind that reconciliation should NOT be performed if there
are pending items in the local queue):

1. Obtain a list of apps installed locally.

2. Create an empty list that will contain "actions".

3. For each app in the set of remote apps, determine if the app is present in the local set.

  a) If the remote app has the "hidden" flag set, add the app object to the actions list as an "uninstall" and proceed to the next app. (Note: this is not generally expected to occur since an app is only marked "hidden" if it has already been uninstalled on all the user's devices. However, the step is needed to gracefully handle clients that predate the Device API and used this flag to mark an app as uninstalled).

  b) If the app is present locally, check if the installTime of the local app object is earlier than the installTime of the remote app object. If so, add this app to the action list as a "re-install".

  c) If the app is not present, add the app to the action list as an "install".

4. Add all local apps not present in the remote set to the action list as "uninstall".

When the actions list has been populated as described above, the changes may be applied. Iterate over all the entries in the actions list:

1. For apps marked as a "re-install" or "install", fetch the manifest. Then, install the app (via an API that modifies the local app registry, and allows you to specify the manifest in the app object). This should automatically set the installTime of the local app object to the current time. Calling navigator.mozApps.install() for an app that already exists locally is designed to act as a re-install and will update the app record.

2. If the app was marked an an "uninstall", remove the app from the local app registry.

IMPORTANT: When reconciliation is taking place and the resulting changes are
being applied, no GET or PUT operations must be performed. Triggers may fire
as usual, which may result in the local queue being modified, but no network
operations should be performed.

Note on Device API
==================

This document describes interaction with the AitC storage service, which is
responsible for storing the global, canonical list of a user's apps. It will
contain, for example, even apps that the user has uninstalled on some or all of
their devices. However, if an app is uninstalled on all of the user's devices
the "hidden" flag in the app object on the storage server will be set to true.

All other app states will be device-specific and stored separately via the
Device API (TBD).

Acquired vs. Installed
======================

An app is said to be acquired when the user installs an app on any of their
devices. An app is considered to be installed if it is able to be launched via
the navigator.mozApps API (This varies from platform to platform, but on the
Desktop, it means that a native launch target for the app is present i.e.
/Application on the Mac, or Start Menu on Windows).

All installed apps are also acquired, but not vice-versa.

It is possible for the user to uninstall an app from all their devices, but
the app is still considered as acquired for that user. Generally, no app records
are ever removed from the AitC storage server, and thus serves as a
purchase/install history for that user, including apps they no longer use.

The DELETE HTTP request is reserved for removing data from the AitC storage
server when explicitly requested by the user, for reasons like privacy or
choosing to move to a different AitC service provider.
