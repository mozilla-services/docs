======
Statsd
======

Loop-Server have got a number of Statsd counters and timers that can
help monitor what's going on in near real-time.

Statsd Counters
###############

Here is a list of the statsd counters loop-server provides:

- ``loop-activated-users``: Incremented when a new Hawk Session is created for a user.
- ``loop-call-urls``: Incremented when a new call-url is created.
- ``loop.simplepush.call``: Incremented when a call is made to a SimplePush URL
- ``loop.simplepush.call.(success|failures)``: Count SP calls success and failures
- ``loop.simplepush.call.{reason}``: Incremented when a call is made
  to a SimplePush URL for a given reason
- ``loop.simplepush.call.{reason}.(success|failures)``: Count success
  or failures when a call is made to a SimplePush URL for a given
  reason.

Statsd Timers
#############

Here is a list of the statsd timers loop-server provides:

- ``loop.aws.write``: Time AWS write calls.
- ``loop.aws.read``: Time AWS read calls.
- ``loop.aws.remove``: Time AWS deletion object calls.
- ``loop.filesystem.write``: Time AWS write calls.
- ``loop.filesystem.read``: Time AWS read calls.
- ``loop.filesystem.remove``: Time AWS deletion object calls.
- ``loop.tokbox.createSession``: Time TokBox createSession calls.
