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
        "lastPingDate": "2013-01-07",
        "thisPingDate": "2013-01-07",
        "version": 1
        "data": {
            "days": {
                "2012-07-19": {
                    "org.mozilla.crashes.crashes.1": {
                        "submitted": 1
                    }
                },
                "2012-08-15": {
                    "org.mozilla.crashes.crashes.1": {
                        "submitted": 2
                    }
                },
                "2013-01-07": {
                    "org.mozilla.addons.counts.1": {
                        "plugin": 2,
                        "theme": 1
                    },
                    "org.mozilla.appInfo.appinfo.1": {
                        "isDefaultBrowser": 0
                    },
                    "org.mozilla.appInfo.versions.1": {
                        "version": [
                            "20.0a1"
                        ]
                    },
                    "org.mozilla.appSessions.previous.1": {
                        "cleanActiveTime": [
                            51920,
                            224188
                        ],
                        "cleanTotalTime": [
                            51920,
                            359209
                        ],
                        "firstPaint": [
                            1597,
                            1199
                        ],
                        "main": [
                            29,
                            32
                        ],
                        "sessionRestored": [
                            1784,
                            1339
                        ]
                    }
                }
            },
            "last": {
                "org.mozilla.addons.active.1": {
                    "{07b90314-1e79-c84a-4b47-fb7e1853be39}": {
                        "appDisabled": false,
                        "foreignInstall": true,
                        "installDay": 15513,
                        "scope": 8,
                        "type": "plugin",
                        "updateDay": 15513,
                        "userDisabled": false,
                        "version": "14.5.0"
                    },
                    "{470c11d9-f59f-097a-bb98-2d4102ece420}": {
                        "appDisabled": false,
                        "foreignInstall": true,
                        "installDay": 15695,
                        "scope": 8,
                        "type": "plugin",
                        "updateDay": 15695,
                        "userDisabled": false,
                        "version": "11.5.502.136"
                    },
                    "{972ce4c6-7e08-4474-a285-3208198ce6fd}": {
                        "appDisabled": false,
                        "foreignInstall": false,
                        "hasBinaryComponents": false,
                        "installDay": 15712,
                        "scope": 4,
                        "type": "theme",
                        "updateDay": 15712,
                        "userDisabled": false,
                        "version": "20.0a1"
                    }
                },
                "org.mozilla.appInfo.appinfo.1": {
                    "appBuildID": "20130106161840",
                    "distributionID": "",
                    "distributionVersion": "",
                    "hotfixVersion": "",
                    "id": "{ec8030f7-c20a-464f-9b0e-13a3a9e97384}",
                    "locale": "en-US",
                    "name": "Firefox",
                    "os": "Darwin",
                    "platformBuildID": "20130106161840",
                    "platformVersion": "20.0a1",
                    "updateChannel": "default",
                    "vendor": "Mozilla",
                    "version": "20.0a1",
                    "xpcomabi": "x86_64-gcc3"
                },
                "org.mozilla.appSessions.current.1": {
                    "activeTime": 34561,
                    "firstPaint": 1223,
                    "main": 28,
                    "sessionRestored": 1370,
                    "startDay": 15712,
                    "totalTime": 62046
                },
                "org.mozilla.profile.age.1": {
                    "profileCreation": 15712
                },
                "org.mozilla.sysinfo.sysinfo.1": {
                    "architecture": "x86-64",
                    "cpuCount": 8,
                    "memoryMB": 8192,
                "name": "Darwin",
                "version": "12.2.0"
                }
            }
        },
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

