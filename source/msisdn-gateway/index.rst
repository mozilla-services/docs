.. _msisdn-gateway:

==============
MSISDN Gateway
==============

Goal of the Service
===================

MSISDN Gateway server allows people to log-on BrowserID applications
using a validated phone number.

MSISDN Gateway server propose multiple ways to validate the phone number with regards to the country, operator and validation cost.

Assumptions
===========

- The MSISDN supports multiple verification flows with regards to the
  MSISDN and MCC/MNC codes.

- The client can discover availables verification methods using
  the `/discover` endpoint.

- The client `/register` to get an Hawk session that will be valid until
  a `/unregister` call.

- The client can verify one and only one number per session.

- The client can use its Hawk session to generate as many BrowserID
  certificates (valid for maximum a day) as needed until
  the `/unregister` call, there is not automatic expiration of the Hawk
  session.

- A mobile number can be validated by multiple session (one per device
  or per app. i.e: One for Loop and one for the Marketplace.)


Documentation content
=====================

.. toctree::
   :maxdepth: 2

   apis
   

Resources
=========

- Server: https://github.com/mozilla-services/msisdn-gateway
- Test webapp: https://github.com/ferjm/msisdn-verifier-client
