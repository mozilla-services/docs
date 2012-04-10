===============
Server API v1.0
===============

General description
===================

The URL for a Sreg request is structured as follows::

    http://<server name>/<username>/<further instruction>

The Sync User API has a set of :ref:`respcodes`
to cover errors in the request or on the server side. The format of a
successful response is defined in the appropriate request method section.


APIs
====

**GET** **https://server/username/node/weave**

    Gets the user a weave node. In general, if the Sreg version is called, it
    is expected that a new node will be assigned (client should already have
    failed to get the node out of ldap), but this is not necessarily the case,
    and it can return a currently assigned node.

    The plan is to abstract this call into a separate api that handles node
    assignment, but it is noted here to make sure we remain backwards
    compatible until that work is complete.

    Return value: <node>

    node may be 'null' if no node can be assigned at this time. Note that
    the returned value is a json-encoded value, so strings are quoted.

    Possible errors:

    - 503: there was an error getting a node | empty body
    - 404: user not found | empty body


**GET** **https://server/username/password_reset_code**

    Generates a reset code and mails it to the email address associated with
    <username>. For security reasons, it does not return the code to the
    registration server.

    Sreg uses an internal constant to determine the URL to send users to in the
    email. It isn't clear whether this will pose a problem in the future.

    Return value:

    - 0 on success

    Possible errors:

    - 503: problems with looking up the user or sending the email | empty body
    - 400: no email address on file for user | WEAVE_NO_EMAIL_ADRESS
    - 404: user not found | empty body


**PUT** **https://server/username**

    Requests that an account be created for *username*

    The body is a JSON mapping and should include:

    - password: the password to be associated with the account.
    - e-mail: Email address associated with the account.

    The server will return the username in a json-encoded value.

    Possible errors:

    - 503: there was an error creating the reset code
    - 400: 4 (user already exists)
    - 400: 6 (Json parse failure)


**PUT** **https://server/username/password**

    Changes the password associated with the account to the value specified
    in the PUT body.

    The PUT body is a JSON mapping containing:

    - reset_code: the reset code
    - password: the new password

    Note that the server does not check if the password is valid.
    This should be done by the client.

    Return values:

    - 0: The operation was successful
    - 400: 7 (Missing password field)
    - 400: 10 (Invalid or missing password reset code)
    - 400: 6 (Json parse failure)
    - 404: the user does not exists in the database
    - 503: there was an error updating the password
      (including a potentially bad reset code)


**DELETE** **https://server/username/password_reset_code**

    Removes a password reset code, if any exists.

    Return value:

    - 0 on success

    Possible errors:

    - 503: there was an error removing the password reset code
    - 404: the user does not exist in the database


**DELETE https://server/username**

    Delete the user's account.

    The body is a JSON mapping and should include:

    - password: The user's password for confirmation.

    Return Value:

    - 0 on success
    - 400: 7 (Missing password field)
    - 400: 6 (Json parse failure)
    - 404: the user does not exist in the database
    - 503: there was an error removing the user (including a potential bad password)
