.. _websockets-apis:

Websockets APIs
###############

During the setup phase of a call, the websocket protocol is used to let clients
broadcast their state to other clients and to listen to changes.

The client will establish a WebSockets connection to the resource indicated in
the "progressURL" when it receives it. The client never closes this connection;
that is the responsibility of the server. The times at which the server closes
the connection are detailed below. If the server sees the client close the
connection, it assumes that the client has failed, and informs the other party
of such call failure.

For forward compatibility purposes:

* Unknown fields in messages are ignored
* Unknown message types received by the client (indicating an earlier release)
  result in the client sending an "error" message ({"messageType": "error",
  "reason": "unknown message"}). The call setup should continue.
* Unknown message types received by the server result in the server sending an
  "error" message (as above); however, since this situation can only arise due to
  a misimplemented client or an out-of-date server, it results in call setup
  failure. The server closes the connection.

Call Setup States
=================

Call setup goes through the following states:

.. image:: /images/loop-call-setup-state.png

Call Progress Protocol
======================

Initial Connection (hello)
--------------------------

Upon connecting to the server, the client sends an immediate "hello" message,
which serves two purposes: it identifies the call that the progress channel
corresponds to (using the "callId"), as well as authenticating the connecting
user, so that they can be verified to be authorized to view/impact the call
setup state.

Note that the callId with which this connection is to be associated is encoded
as a component of the WSS URL.

UA -> Server::

   {
     "messageType": "hello",
     "auth": "''<authentication information>''"
   }


* `auth`: Information to authenticate the user, so that they can be verified to
  be authorized to access call setup information. This is the `websocketToken`
  returned by a POST to /calls/{token}, POST /calls and GET /calls.

If the hello is valid (the callId is known, the auth information is valid, and
the authenticated user is a party to the call), then the server responds with a
"hello." This "hello" includes the current call setup state.

Server -> UA::

   {
     "messageType": "hello",
     "state": "alerting"
     // may contain "reason" field for certain states.
   }

* `state`: See states in "progress", below.

If the hello is invalid for any reason, then the server sends an "error"
message, as follows. It then closes the connection.

Server -> UA::

   {
     "messageType": "error",
     "reason": "unknown callId"
   }

`reason`: The reason the hello was rejected:

* `unknown callId`
* `invalid authentication` - The auth information was not valid
* `unauthorized` - The auth information was valid, but did not match the
   indicated callId

Call Progress State Change (progress)
-------------------------------------

The server informs users of the current state of call setup. The state sent to
both parties ''is always the same state''. So, for example, when a user rejects
a call, he will receive a "progress" message with a state of "terminated" and a
reason of "rejected."

Server -> UA::

   {
     "messageType": "progress",
     "state": "alerting"
     // may contain optional "reason" field for certain events.
   }

Defined states are:

* `init`: The call is starting, and the remote party is not yet being alerted.
* `alerting`: The called party is being alerted (triggered by remote party
   sending a "hello" message).
* `terminated`: The call is no longer being set up. After sending a
  "terminated" message, the server closes the WebSockets connection. This message
  will include a "reason" field with one of the reason values described below.
* `connecting`: The called party has indicated that he has answered the call,
  but the media is not yet confirmed
* `half-connected`: One of the two parties has indicated successful media set
  up, but the other has not yet.
* `connected`: Both endpoints have reported successfully establishing media.
  After sending a "connected" message, the server closes the WebSockets
  connection.

Client Action (action)
----------------------

During call setup, clients send progress information about their own state so
that it can be reflected in the call state.

UA -> Server::

   {
     "messageType": "action",
     "event": "accept"
     // May contain "reason" field for certain events
   }

Defined event types are:

* `accept`: Only sent by called party. The user has answered this call. This is
  sent before the called party attempts to set up the media.
* `media-up`: Sent by both parties. Communications have been successfully
  established.
* `terminate`: Sent by both parties. Ends attempt to set up call. Includes a
  "reason" field with one of values detailed below.

Termination Reasons
===================

The following reasons appear in "action"/"terminate" and "progress" /
"terminated" messages. The "√" columns indicate whether the indicated element
is permitted to generate the reason. When generated a "terminated" message as
the result of receiving a "terminate" action from either client, the server
will copy the reason code from the "terminate" action message into all
resulting "terminated" progress messages, ''even if it does not recognize the
reason code''.

To provide for forwards compatibility, clients must be prepared to process
"terminated" progress messages with unknown reason codes. The reaction to this
situation should be the display of a generic "call setup failed" message.

If the server receives an action of "terminate" with a reason it does not
recognize, it copies that reason into the resulting "terminated" message.

==================   ======    ======    ======    ========================================
    Reason           Caller    Callee    Server                    Note
==================   ======    ======    ======    ========================================
reject                         √                   The called user has declined the call.
busy                           √                   The user is logged in, but cannot answer
                                                   the call due to some current state
                                                   (e.g., DND, in another call).
timeout                        √         √         The call setup has timed out (The
                                                   called party's client has exceeded the
                                                   amount of time it is willing to alert
                                                   the user, or one of the server's timers
                                                   expired)
cancel                √                            The calling party has cancelled a pending
                                                   call.
media-fail                     √                   The called user has declined the call.
user-unknown                             √         The indicated user id does not exist.
closed                                   √         The other user's WSS connection closed
                                                   unexpectedly.
==================   ======    ======    ======    ========================================

Timer Supervision
=================

Server Timers
-------------

The server uses three timers to ensure that the call created by a setup attempt
is cleaned up in a timely fashion.

Supervisory Timer
~~~~~~~~~~~~~~~~~

After responding to a ```POST /call/{token}``` or ```POST /call/user```
message, the server starts a supervisory timer of 10 seconds.

* If the calling user does not connect and send a "hello" in this time period,
  the server considers the call to be failed. The called user, if connected,
  will receive a "progress"/"terminated" message with a reason of "timeout".
* If the called user does not connect and send a "hello" in this time period,
  the server considers the call to be failed. The calling user, if connected,
  will receive a "progress"/"terminated" message with a reason of "timeout".

Ringing Timer
~~~~~~~~~~~~~

Upon receiving a "hello" from the called user, the server starts a ringing
timer of 30 seconds. If the called user does not send an "accept" message in
this time period, then both parties will receive a "progress"/"terminated"
message with a reason of "timeout".

Connection Timer
~~~~~~~~~~~~~~~~

Upon receiving an "accept" from the called user, the server starts a connection
timer of 10 seconds. If the call setup state does not reach "connected" in this
time period, then both parties will receive a "progress"/"terminated" message
with a reason of "timeout".

Client Timers
-------------

Response Timer
~~~~~~~~~~~~~~

Every client message triggers a response from the server: "hello" results in
"hello" or "error"; and "action" will always cause a corresponding "progress"
message to be sent. When the client sends a message, it sets a timer for 5
seconds. If the server does not respond in that time period, it disconnects
from the server and considers the call failed.

Media Setup Timer
~~~~~~~~~~~~~~~~~

After sending a "media-up" action, the client sets a timer for 10 seconds. If
the server does not indicate that the call setup has entered the "connected"
state before the timer expires, the client disconnects from the server and
considers the call failed.

Alerting Timer
~~~~~~~~~~~~~~

We may wish to let users configure the maximum amount of time the call is
allowed to ring (up to 30 seconds) before it considers it unanswered. This
timer would start as soon as user alerting begins. If it expires before the
call is set up, then the called party sends a "action"/"disconnect" message
with a reason of "timeout."
