.. _server_fxa:

=======================
Mozilla Accounts Server
=======================

DEPRECATION NOTE
==============================
This repo has been archived and the documentation is no longer maintained.
Sync and Tokenserver docs and code are in the `syncstorage-rs` GitHub repo.
You can find the repo for this service `here <https://github.com/mozilla-services/syncstorage-rs>`_ and the maintained documentation `here <https://mozilla-services.github.io/syncstorage-rs/>`_.


The Mozilla accounts server provides a centralized database of all user
accounts for accessing Mozilla-hosted services.

By default, Firefox will use Mozilla's hosted accounts server at `<https://accounts.firefox.com>`_.  This configuration will work well for most use-cases,
including for those who want to :ref:`self-host a storage server <howto_run_sync15>`.  User who want to minimize their dependency on Mozilla-hosted services
may also :ref:`self-host an accounts server <howto_run_fxa>`, but this setup is incompatible with other Mozilla-hosted services.

- Protocol documentation: https://github.com/mozilla/fxa/blob/main/packages/fxa-auth-server/docs/api.md
- API server code: https://github.com/mozilla/fxa/blob/main/packages/fxa-auth-server/
- Web interface code: https://github.com/mozilla/fxa/blob/main/packages/fxa-content-server/
