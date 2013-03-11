.. healthreport_index:

=====================
Firefox Health Report
=====================

The Firefox Health Report is a daily client *ping* that uploads basic
product usage information.

Payload Format
==============

Currently, the Firefox Health Report is submitted as a compressed JSON
document. Here is an example JSON document::

    {
      "version": 1,
      "thisPingDate": "2013-03-11",
      "lastPingDate": "2013-03-10",
      "data": {
        "last": {
          "org.mozilla.addons.active": {
            "masspasswordreset@johnathan.nightingale": {
              "userDisabled": false,
              "appDisabled": false,
              "version": "1.05",
              "type": "extension",
              "scope": 1,
              "foreignInstall": false,
              "hasBinaryComponents": false,
              "installDay": 14973,
              "updateDay": 15317
            },
            "places-maintenance@bonardo.net": {
              "userDisabled": false,
              "appDisabled": false,
              "version": "1.3",
              "type": "extension",
              "scope": 1,
              "foreignInstall": false,
              "hasBinaryComponents": false,
              "installDay": 15268,
              "updateDay": 15379
            },
            "_v": 1
          },
          "org.mozilla.appInfo.appinfo": {
            "_v": 1,
            "appBuildID": "20130309030841",
            "distributionID": "",
            "distributionVersion": "",
            "hotfixVersion": "",
            "id": "{ec8030f7-c20a-464f-9b0e-13a3a9e97384}",
            "locale": "en-US",
            "name": "Firefox",
            "os": "Darwin",
            "platformBuildID": "20130309030841",
            "platformVersion": "22.0a1",
            "updateChannel": "nightly",
            "vendor": "Mozilla",
            "version": "22.0a1",
            "xpcomabi": "x86_64-gcc3"
          },
          "org.mozilla.profile.age": {
            "_v": 1,
            "profileCreation": 12444
          },
          "org.mozilla.appSessions.current": {
            "_v": 3,
            "startDay": 15773,
            "activeTicks": 522,
            "totalTime": 70858,
            "main": 1245,
            "firstPaint": 2695,
            "sessionRestored": 3436
          },
          "org.mozilla.sysinfo.sysinfo": {
            "_v": 1,
            "cpuCount": 8,
            "memoryMB": 16384,
            "architecture": "x86-64",
            "name": "Darwin",
            "version": "12.2.1"
          }
        },
        "days": {
          "2013-03-11": {
            "org.mozilla.addons.counts": {
              "_v": 1,
              "extension": 15,
              "plugin": 12,
              "theme": 1
            },
            "org.mozilla.places.places": {
              "_v": 1,
              "bookmarks": 757,
              "pages": 104858
            },
            "org.mozilla.appInfo.appinfo": {
              "_v": 1,
              "isDefaultBrowser": 1
            }
          },
          "2013-03-10": {
            "org.mozilla.addons.counts": {
              "_v": 1,
              "extension": 15,
              "plugin": 12,
              "theme": 1
            },
            "org.mozilla.places.places": {
              "_v": 1,
              "bookmarks": 757,
              "pages": 104857
            },
            "org.mozilla.searches.counts": {
              "_v": 1,
              "google.urlbar": 4
            },
            "org.mozilla.appInfo.appinfo": {
              "_v": 1,
              "isDefaultBrowser": 1
            }
          }
        }
      }
    }


Top-level Properties
--------------------

The main JSON object contains the following properties:

lastPingDate
    UTC date of the last upload. If this is the first upload from this client,
    this will not be defined.

thisPingDate
    UTC date when this payload was constructed.

version
    Integer version of this payload format. Currently only 1 is defined.

data
    Object holding data constituting health report.

Data Properties
---------------

The bulk of the health report is contained within the *data* object. This
object has the following keys:

days
   Object mapping UTC days to measurements from that day.
last
   Object mapping measurement names to their values.

Measurements
------------

Related data in the payload is organized into measurements. The value of each
measurement is defined by the measurement itself.

