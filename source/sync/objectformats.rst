.. _sync_objectformats:

======================
Firefox object formats
======================

Decrypted data objects are cleartext JSON strings.

Each collection can have its own object structure. This page documents the
format of each collection.

The object structure is versioned with the version metadata stored in the
meta/global payload.

The following sections, named by the corresponding collection name, describe
the various object formats and how they're used. Note that object structures
may change in the future and may not be backwards compatible.

In addition to these custom collection object structures, the Encrypted DataObject
adds fields like *id* and *deleted*. Also, remember that there is data at the
Weave Basic Object (WBO) level as well as *id*, *modified*, *sortindex* and
*payload*.

Add-ons
=======

Version 1
---------

Version 1 is likely only affiliated with storage format 5 clients.

* **addonID** *string*: Public identifier of add-on. This is the *id* attribute from an Addon object obtained from the AddonManager.
* **applicationID** *string*: The application ID the add-on belongs to.
* **enabled** *bool*: Indicates whether the add-on is enabled or disabled. true means enabled.
* **source** *string*: Where the add-on came from. *amo* means it came from addons.mozilla.org or a trusted site.

Bookmarks
=========

Version 1
---------

One bookmark record exists for each *bookmark item*, where an item may actually
be a folder or a separator. Each item will have a *type* that determines what
other fields are available in the object. The following sections describe the
object format for a given *type*.

Each bookmark item has a *parentid* and *predecessorid* to form a structure
like a tree of linked-lists to provide a hierarchical ordered list of bookmarks,
folders, etc.

bookmark
^^^^^^^^

This describes a regular bookmark that users can click to view a page.

* **title** *string*: name of the bookmark
* **bmkUri** *string* uri of the page to load
* **description** *string*: extra description if provided
* **loadInSidebar** *boolean*: true if the bookmark should load in the sidebar
* **tags** *array of strings*: tags for the bookmark
* **keyword** *string*: alias to activate the bookmark from the location bar
* **parentid** *string*: GUID of the containing folder
* **parentName** *string*: name of the containing folder
* **predecessorid** *string*: GUID of the item before this (empty if it's first)
* **type** *string*: "bookmark"

microsummary
^^^^^^^^^^^^

`Microsummaries <https://developer.mozilla.org/en/Microsummary_topics>`_ allow pages to be summarized for viewing from the toolbar. This extends *bookmark*, so the usual *bookmark* fields apply.

* **generatorUri** *string*: uri that generates the summary
* **staticTitle** *string*: title to show when no summaries are available
* **title** *string*: name of the microsummary
* **bmkUri** *string* uri of the page to load
* **description** *string*: extra description if provided
* **loadInSidebar** *boolean*: true if the bookmark should load in the sidebar
* **tags** *array of strings*: tags for the bookmark
* **keyword** *string*: alias to activate the bookmark from the location bar
* **parentid** *string*: GUID of the containing folder
* **parentName** *string*: name of the containing folder
* **predecessorid** *string*: GUID of the item before this (empty if it's first)
* **type** *string*: "microsummary"

query
^^^^^

Place queries are special bookmarks with a place: uri that links to an existing folder/tag. This extends *bookmark*, so the usual *bookmark* fields apply.

* **folderName** *string*: name of the folder/tag to link to
* **queryId** *string* (optional): identifier of the smart bookmark query

* **title** *string*: name of the query
* **bmkUri** *string* place: uri query
* **description** *string*: extra description if provided
* **loadInSidebar** *boolean*: true if the bookmark should load in the sidebar
* **tags** *array of strings*: tags for the query
* **keyword** *string*: alias to activate the bookmark from the location bar

* **parentid** *string*: GUID of the containing folder
* **parentName** *string*: name of the containing folder
* **predecessorid** *string*: GUID of the item before this (empty if it's first)
* **type** *string*: "query"

folder
^^^^^^

Folders contain bookmark items like bookmarks and other folders.

* **title** *string*: name of the folder

* **parentid** *string*: GUID of the containing folder
* **parentName** *string*: name of the containing folder
* **predecessorid** *string*: GUID of the item before this (empty if it's first)
* **type** *string*: "folder"

livemark
^^^^^^^^

`Livemarks <https://developer.mozilla.org/en/Using_the_Places_livemark_service>`_ act like folders with a dynamic list bookmarks, e.g., a RSS feed. This extends *folder*, so the usual *folder* fields apply.

* **siteUri** *string*: site associated with the livemark
* **feedUri** *string*: feed to get items for the livemark

* **title** *string*: name of the livemark

* **parentid** *string*: GUID of the containing folder
* **parentName** *string*: name of the containing folder
* **predecessorid** *string*: GUID of the item before this (empty if it's first)
* **type** *string*: "livemark"

separator
^^^^^^^^^

Separators help split sections of a folder.

* **pos** *string*: position (index) of the separator

* **parentid** *string*: GUID of the containing folder
* **parentName** *string*: name of the containing folder
* **predecessorid** *string*: GUID of the item before this (empty if it's first)
* **type** *string*: "separator"

Version 2
---------

Same as engine version 1, except:

* the predecessorid is removed from all records,
* instead folder and livemark records have a children attribute which is an array of child GUIDs in order of their appearance in the folder:
* **children** *array of strings*: ordered list of child GUIDs
* the special folders 'menu' and 'toolbar' now have records that are synced, purely to maintain order within them according to their '''children''' array.

Clients
=======

Client records identify a user's one or multiple clients that are accessing the
data. The existence of client records can change the behavior of the Firefox
Sync client -- multiple clients and/or mobile clients result in syncs to happen
more frequently.

* **name** *string*: name of the client connecting
* **type** *string*: type of the client: "desktop" or "mobile"
* **commands** *array*: commands to be executed upon next sync

Forms
=====

Form data is used to give suggestions for autocomplete for a HTML text input form. One record is created for each form entry.

* **name** *string*: name of the HTML input field
* **value** *string*: value to suggest for the input

History
=======

Version 1
---------

Every page a user visits generates a history item/page. One history (page) per record.

* **histUri** *string*: uri of the page
* **title** *string*: title of the page
* **visits** *array of objects*: a number of how and when the page was visited
* **date** *integer*: datetime of the visit
* **type** *integer*: `transition type <https://developer.mozilla.org/en/nsINavHistoryService#Constants>`_ of the visit

Version 2
---------

.. note::

  Proposal corresponding with storage format 6.

History visits are now stored as a timeline/stream of visits. The historical
information for a particular site/URL is spread out of N>=1 records.

Payloads have the structure::

    {
      "items": [
        "uri": "http://www.mozilla.org/",
        "title": "Mozilla",
        "visits": {
          1: [1340757179.82, 184],
          2: [1340341244.31, 12, 4]
        }
      ]
    }

The bulk of the payload is a list of history items. Each item is both a place
and a set of visits.

* **uri** *string*: URI of the page that was visited.
* **title** *string*: Title of the page that was visited.
* **visits** *object*: Mapping of visit type to visit times.

The keys in **visits** define the transition type for the visit. They can be
one of the following:

* **1**: A link was followed.
* **2**: The URL was typed by the user.
* **3**: The user followed a bookmark.
* **4**: Some inner content was loaded.
* **5**: A permanent redirect was followed.
* **6**: A temporary redirect was followed.
* **7**: The URL was downloaded.
* **8**: User follows a link that was in a frame.

These correspond to nsINavHistoryService's
`transition type constants <https://developer.mozilla.org/en/nsINavHistoryService#Constants>`.

The values for each visit type are arrays which encode the visit time. The
initial array element is the wall time of the first visit being recorded in
seconds since epoch, typically with millisecond resolution. Each subsequent
value is the number of seconds elapsed since the previous visit. The values::

    [100000000.000, 10.100, 5.200]

Correspond to the times::

    100000000.000
    100000010.100
    100000015.300

The use of deltas to represent times is to minimize the serialized size of
visits.

Passwords
=========

Saved passwords help users get back into websites that require a login such as HTML input/password fields or HTTP auth.

* **hostname** *string*: hostname that password is applicable at
* **formSubmitURL** *string*: submission url (GET/POST url set by <form>)
* **httpRealm** *string*: the HTTP Realm for which the login is valid. if not provided by the server, the value is the same as hostname
* **username** *string*: username to log in as
* **password** *string*: password for the username
* **usernameField** *string*: HTML field name of the username
* **passwordField** *string*: HTML field name of the password

Preferences
===========

Version 1
---------

Some preferences used by Firefox will be synced to other clients. There is only one record for preferences with a GUID "preferences".

* **value** *array of objects*: each object describes a preference entry
* **name** *string*: full name of the preference
* **type** *string*: the type of preference (int, string, boolean)
* **value** *depends on type*: value of the preference

Version 2
---------

There is only one record for preferences, using nsIXULAppInfo.ID as the GUID. Custom preferences can be synced by following `these instructions <https://developer.mozilla.org/en/Firefox_Sync/Syncing_custom_preferences>`_.

* **value** *object* containing name and value of the preferences.

Note: The preferences that determine which preferences are synced are now included as well.

Tabs
====

Version 1
---------

Tabs describe the opened tabs on a given client to provide functionality like get-up-n-go. Each client will provide one record.

* **clientName** *string*: name of the client providing these tabs
* **tabs** *array of objects*: each object describes a tab
* **title** *string*: title of the current page
* **urlHistory** *array of strings*: page urls in the tab's history
* **icon** *string*: favicon uri of the tab
* **lastUsed** *string* or *integer*: string representation of Unix epoch (in seconds) at which the tab was last accessed. Or the integer 0. Your code should accept either. This is ghastly; we apologize.

Version 2
---------

.. note::

  Proposal corresponding with storage format 6.

In version 2, each tab is represented by its own record. (This is a change from
version 1.)

The payload of the BSO is a JSON object containing the following fields:

* **clientID** *string*: ID of the client this tab originated on.
* **title** *string*: Title of page that is active in the tab.
* **history** *array of strings*: URLs in this tab's history. Initial element
  is the current URL. Subsequent URLs were previously visited URLs.
* **lastUsed** *number*: Time in seconds since Unix epoch that tab was last
  active.
* **icon** *string*: Base64 encoded favicon image.
* **groupName** *string*: Name of tab group this tab is associated with. This
  is usually used for presentation purposes and is typically the same string
  across all records in a particular tab group.
