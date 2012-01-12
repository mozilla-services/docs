========
Security
========

DOS Defense
===========

- Least Recently Used (LRU) queue approach for monitoring IP addresses 
  issuing frequent requests

 - Configurable threshold for adding IP address to Blacklist/Penalty Box
 - Configurable time-out for IP addresses added to Blacklist/Penalty Box

- A single shared blacklist will exist within memcache
- LRU queues will be unique to each server and will penalize an IP to the 
  shared blacklist on memcache
- All thresholds will be controlled via the configuration page

TearDown DOS Defense 
====================

- Tear down requires valid channel and valid x-keyexchange-id value
- Statistically unlikely. Channel is 4 characters and keyexchange-id 
  is 255 characters
- Brute force attempts will generate lots of noise and will be limited 
  per DOS defense 

Logging Points
==============

CEF Logging
:::::::::::

- Bad action taken against a valid channel id (denoted by 400 error code)

 - Examples: non-existent x-keyexchange-id, bad x-keyexchange-id

- Action taken against an invalid channel id

 - Examples: request for properly formed, but not existing, channel id

- IP address sent to black list due to DOS prevention controls

 - Examples: Flood of requests from a single IP

- Client fallback to original sync method
 
 - Examples: Client unable to complete J-PAKE sync for any number of reasons 
   and falls back to original sync approach
 - Reported by client to server via reporting API

Application Logging
:::::::::::::::::::

- Full application logging will be created to enable incident response review
- Logged to application server and not via CEF
- Logs will include:

  - Timestamp
  - IP address 
  - Full URL
  - x-keyexchange-id
  - Event
  - Other non-essential headers will be discarded

Admin Web Page
==============

- A small web administrator page will be created which will allow an admin to
  view all IP addresses that are currently blacklisted.
- The admin will be able to un-block any of the IP addresses through this page
- Otherwise the IP address will be removed from the black list after the time 
  has elapsed that is defined within the configuration file 
- Access to the web page will be password-protected with a simple .htaccess 
  file and IP filtering access (10.*.*.*)
