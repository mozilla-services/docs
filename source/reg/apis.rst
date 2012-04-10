=============
User API v1.0
=============


General description
===================

The URL for a Reg request is structured as follows::

    https://<server name>/<api path set>/<version>/<username>/<further instruction>


+---------------------+---------------------------+-------------------------------------------------------------------+
| Component           | Mozilla Default           | Description                                                       |
+=====================+===========================+===================================================================+
| server name         | auth.services.mozilla.com | the hostname of the server                                        |
+---------------------+---------------------------+-------------------------------------------------------------------+
| pathname            | user                      | the prefix associated with the service on the box                 |
+---------------------+---------------------------+-------------------------------------------------------------------+
| version             | 1.0                       | The API version.                                                  |
+---------------------+---------------------------+-------------------------------------------------------------------+
| username            | (none)                    | the name of the object (user) to be manipulated                   |
+---------------------+---------------------------+-------------------------------------------------------------------+
| further instruction | (none)                    | The additional function information as defined in the paths below |
+---------------------+---------------------------+-------------------------------------------------------------------+


Certain functions use HTTP basic auth (over SSL, so as to maintain password
security). If the auth username does not match the username in the path, the
server will issue an Error Response.

The Sync User API has a set of :ref:`respcodes` to cover errors in the request 
or on the server side. The format of a successful response is defined in the appropriate request method section.


APIs
====

**GET** **https://server/pathname/version/username**

    Returns 1 if the username is in use, 0 if it is available. The answer is in
    plain text.

    Possible errors:

    - 503: there was an error getting the information


**GET** **https://server/pathname/version/username/node/weave**

    Returns the Weave (aka Sync) Node that the client is located on.
    Sync-specific calls should be directed to that node.

    Return value: the node URL, an unadorned (not JSON) string.

    node may be 'null' if no node can be assigned at this time,
    probably due to sign up throttling.

    Possible errors:

    - 503: there was an error getting a node | empty body
    - 404: user not found | empty body


**GET** **https://server/pathname/version/username/password_reset**

    Requests a password reset email be mailed to the email address on file.
    Returns 'success' if an email was successfully sent.

    If captchas are enabled for the site, requires captcha-challenge and
    captcha-response parameters.

    Return value:

    - "success"

    Possible errors:

    - 503: problems with looking up the user or sending the email
    - 400: 12 (No email address on file)
    - 400: 3 (Incorrect or missing username)
    - 400: 2 (Incorrect or missing captcha)


**PUT** **https://server/pathname/version/username**

    Requests that an account be created for *username*.

    The body is a JSON mapping and should include:

    - password: the password to be associated with the account.
    - e-mail: Email address associated with the account.
    - captcha-challenge: The challenge string from the captcha.
    - captcha-response: The response to the captcha.

    An **X-Weave-Secret** can be provided containing a secret string known
    by the server. When provided, it will override the captcha. This is
    useful for testing and automation.

    The server will return the lowercase username on success.

    Possible errors:

    - 503: there was an error creating the reset code
    - 400: 4 (user already exists)
    - 400: 6 (Json parse failure)
    - 400: 12 (No email address on file)
    - 400: 7 (Missing password field)
    - 400: 9 (Requested password not strong enough)
    - 400: 2 (Incorrect or missing captcha)


**POST** **https://server/pathname/version/username/password**

    Changes the password associated with the account to the value specified
    in the POST body.

    NOTE: Requires basic authentication with the username and (current)
    password associated with the account. The auth username must match the
    username in the path.

    Alternately, a valid X-Weave-Password-Reset header can be used,
    if it contains a code previously obtained from the server.

    Return values: "success" on success.

    Possible errors:

    - 400: 7 (Missing password field)
    - 400: 10 (Invalid or missing password reset code)
    - 400: 9 (Requested password not strong enough)
    - 404: the user does not exists in the database
    - 503: there was an error updating the password
    - 401: authentication failed


**POST** **https://server/pathname/version/username/email**

    Changes the email associated with the account to the value specified
    in the POST body.

    NOTE: Requires basic authentication with the username and password
    associated with the account. The auth username must match the
    username in the path.

    Alternately, a valid X-Weave-Password-Reset header can be used,
    if it contains a code previously obtained from the server.

    Return values: The user email on success.

    Possible errors:

    - 400: 12 (No email address on file)
    - 404: the user does not exists in the database
    - 503: there was an error updating the email
    - 401: authentication failed


**DELETE** **https://server/pathname/version/username**

    Deletes the user account.

    NOTE: Requires simple authentication with the username and password
    associated with the account. The auth username must match the username
    in the path.

    Return value:

    - 0 on success

    Possible errors:

    - 503: there was an error removing the user
    - 404: the user does not exist in the database
    - 401: authentication failed


**GET** **https://server/misc/1.0/captcha_html**

    Returns an html body string containing a reCaptcha challenge captcha.
    The PUT API to create a user will expect the challenge and response
    from this captcha.

    Note: this function outputs html, not json.


X-Weave-Alert
=============

This header may be sent back from any transaction, and contains potential
warning messages, information, or other alerts. The contents are intended
to be human-readable.
