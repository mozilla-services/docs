.. healthreport_index:

=====================
Firefox Health Report
=====================

The Firefox Health Report is a daily client *ping* that uploads basic
product usage information.

Payload Format
==============

Currently, the Firefox Health Report is submitted as a compressed JSON
document. The JSON has the following structure::

    {
        "version": 1,
        "thisPingDate": "2012-11-05",
        "lastPingDate": "2012-11-02",
        "providers": {
          "app-info": {
            "app-info": {
              "name": "app-info",
              "version": 1,
              "fields": {
                "appID": "{ec8030f7-c20a-464f-9b0e-13a3a9e97384}",
                "appVersion": "19.0a1",
                "appVendor": "Mozilla",
                "appName": "Firefox",
                "appBuildID": "20121017174830",
                ...
              }
            }
          },
          "provider-2": {
            "measurement-a": {...},
            "measurement-b": {...}
          }
        }
    }

Data Providers
==============

Application Info
----------------

TODO

Crash Reports
-------------

TODO
