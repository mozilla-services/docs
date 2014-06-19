.. _howto_run_fxa:

====================================
Run your own Firefox Accounts Server
====================================

The Firefox Accounts server is deployed on our systems using RPM packaging,
and we don't provide any other packaging or publish official builds yet.

.. note:: This guide is preliminary and vastly incomplete. If you have any
   questions or find any bugs, please don't hesitate to drop by the IRC channel 
   or mailing list and let us know.


The Firefox Accounts server is hosted in **git** and requires **nodejs**.
Make sure your system has these, or install them:

- git: http://git-scm.com/downloads
- nodejs: http://nodejs.org/download

A self-hosted Firefox Accounts server requires two components: an auth-server
that manages the accounts database, and a content-server that hosts a web-based
user interface.

Clone the fxa-auth-server repository and follow the README to deploy your
own auth-server:

- https://github.com/mozilla/fxa-auth-server/

Clone the fxa-content-server repository and follow the README to deploy your
own content-server:

- https://github.com/mozilla/fxa-content-server/

Now direct Firefox to use your servers rather than the default, Mozilla-hosted
ones.  Enter "about:config" in the URL bar, search for items containing
"fxaccounts", and edit them to use your self-hosted URLs:

  - use your auth-server URL to replace "api.accounts.firefox.com" in
    the following settings:

    - identity.fxaccounts.auth.uri

  - use your content-server URL to replace "accounts.firefox.com" in
    the following settings:

    - identity.fxaccounts.remote.uri
    - identity.fxaccounts.remote.force_auth.uri
    - identity.fxaccounts.settings.uri

Since the Mozilla-hosted sync servers will not trust assertions issued by
third-party accounts servers, you will also need to :ref:`run your own
sync-1.5 server <howto_run_sync15>`.

Please note that the fxa-content-server repository includes graphics and
other assets that make use of Mozilla trademarks.  If you are doing anything
other than running unmodified copies of the software for personal use, please
review the Mozilla Trademark Policy and Mozilla Branding Guidelines:

  - https://www.mozilla.org/en-US/foundation/trademarks/policy/
  - http://www.mozilla.org/en-US/styleguide/identity/mozilla/branding/

You can ask for help:

- on IRC (irc.mozilla.org) in the #fxa channel
- in our Mailing List: https://mail.mozilla.org/listinfo/dev-fxacct
