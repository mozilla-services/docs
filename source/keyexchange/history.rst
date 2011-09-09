=======
History
=======

v3 - DRAFT
==========

- Added a ``version`` attribute to the JSON payloads.

- Requiring longer timeout for the final message (credentials exchange) to
  allow for the account creation flow on Desktop *after* pairing devices.

v2 - 2011-04-26
===============

- Added support for ``If-None-Match`` and ``If-Match`` on ``PUT``
  requests and the corresponding 412 Precondition Failed response code
  to improve reliability on flaky networks.

v1
==

- Initial implementation

