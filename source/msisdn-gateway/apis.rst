=======================
MSISDN Gateway API v1.0
=======================

This document is based on the current status of the server. All the
examples had been done with real calls. It doesn't reflect any future
implementation and tries to stick with the currently deployed version.

This document describes the HTTP API and the SMS API.

HTTP APIs
=========

.. note::

    Unless stated otherwise, all APIs are using application/json for the requests
    and responses content types. Parameters for the GET requests are form
    encoded (?key=value&key2=value2)

To ease testing, you can use `httpie <https://github.com/jkbr/httpie>`_ in
order to make requests. Examples of use with httpie are provided when possible.
In order to authenticate with hawk, you'll need to install the `requests-hawk
module <https://github.com/mozilla-services/requests-hawk>`_

Authentication
--------------

To deal with authentication, the MSISDN Gateway server uses `Hawk
<https://github.com/hueniverse/hawk>`_ sessions. When you
register, you can do so with different authentications schemes, but you are
always given an hawk session back, that you should use when requesting the
endpoints which need authentication.


Derive hawk credentials from the hawk session token
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When authenticating using the `/register` endpoint, you will be given an hawk
session token called `msisdnSessionToken` in the body.

In order to get the hawk credentials to use on the client you will need to:

1. Do an `HKDF derivation <http://en.wikipedia.org/wiki/HKDF>`_ on the given
   session token. You'll need to use the following parameters::

    key_material = HKDF(hawk_session, "", 'identity.mozilla.com/picl/v1/sessionToken', 32*2)

2. The key material you'll get out of the HKDF need to be separated into two
   parts, the first 32 hex characters are the hawk id, and the next 32 ones are the hawk
   key.

   Credentials::

        credentials = {
            'id': keyMaterial[0:32]
            'key': keyMaterial[32:64]
            'algorithm': 'sha256'
        }

If you are writting a client, you might find these resources useful:

- With javascript:
  https://github.com/ferjm/msisdn-verifier-client/blob/master/js/token.js
- With python:
  https://github.com/mozilla-services/requests-hawk/blob/master/requests_hawk/__init__.py


APIs
----

GET /
~~~~~

    Displays version information, for instance::

       http GET localhost:5000 --verbose

    .. code-block:: http

        GET / HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0


        HTTP/1.1 200 OK
        Access-Control-Allow-Credentials: true
        Connection: keep-alive
        Content-Length: 219
        Content-Type: application/json; charset=utf-8
        Date: Mon, 28 Jul 2014 13:52:16 GMT
        ETag: W/"db-3773650714"
        Timestamp: 1406555536

        {
            "description": "The Mozilla MSISDN Gateway", 
            "endpoint": "http://localhost:5000", 
            "homepage": "https://github.com/mozilla-services/msisdn-gateway/", 
            "name": "mozilla-msisdn-gateway", 
            "version": "0.5.0"
        }


POST /register
~~~~~~~~~~~~~~

    Creates a new msisndSessionToken associated with an Hawk session.

    This is the first step to start verifying a new number.

    Example::

        http POST localhost:5000/register --verbose

    .. code-block:: http

        POST /register HTTP/1.1
        Accept: */*
        Accept-Encoding: gzip, deflate
        Content-Length: 0
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0


        HTTP/1.1 200 OK
        Access-Control-Allow-Credentials: true
        Connection: keep-alive
        Content-Length: 94
        Content-Type: application/json; charset=utf-8
        Date: Mon, 28 Jul 2014 13:55:20 GMT
        Timestamp: 1406555720

        {
            "msisdnSessionToken": "8feb2f78227ff8f8d4addd8ba77c06d9ee7acb59d86bd78ae2fd94e242dfd1ee"
        }

    Server should acknowledge your request, return a `msisdnSessionToken`
    and answer with a status code of **200 OK**.

    Potential HTTP error responses include:

    - **429 Too Many Requests:**  Client has sent too many requests
    - **503 Service Unavailable:** Service temporarily unavailable due
      to high load or misconfiguration of the storage backend.


POST /unregister
~~~~~~~~~~~~~~~~

    **Requires authentication**

    Unregister an Hawk session.

    To revoke a device or once we don't want to use this validation
    number anymore, we can unregister the session token to prevent the
    user from continuing to generate BrowserID certificates with it.

    Example::

      http POST localhost:5000/unregister --verbose \
          --auth-type=hawk \
          --auth='8feb2f78227ff8f8d4addd8ba77c06d9ee7acb59d86bd78ae2fd94e242dfd1ee:'

    .. code-block:: http

        POST /unregister HTTP/1.1
        Accept: */*
        Accept-Encoding: gzip, deflate
        Authorization: Hawk mac="Tpny...a+A=", hash="B0we...z8=", id="bc...2f", ts="1406556506", nonce="E_GRLT"
        Content-Length: 0
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0


        HTTP/1.1 204 No Content
        Access-Control-Allow-Credentials: true
        Connection: keep-alive
        Date: Mon, 28 Jul 2014 14:08:26 GMT
        Server-Authorization: Hawk mac="lTGx...PNM=", hash="B0we...Uz8="


    Server should acknowledge your request and answer with a status code of
    **204 No Content**.

    Potential HTTP error responses include:

    - **401 Unauthorized:** The credentials you passed aren't valid.
    - **429 Too Many Requests:**  Client has sent too many requests
    - **503 Service Unavailable:** Service temporarily unavailable due
      to high load or misconfiguration of the storage backend.


POST /discover
~~~~~~~~~~~~~~

    Discover which validation methods are available for a given MSISDN
    number or a MCC/MNC network-code.

    Body parameters:

    - **mcc**, the Mobile Country Code.
    - **mnc**, the Mobile Network Code (optional).
    - **msisdn**, the Mobile Station ISDN Number that is the user phone number
      to validate in its international form i.e 33623456789 (optional).

    Example (with MCC only)::

      http POST localhost:5000/discover mcc=208 --verbose

    .. code-block:: http

        POST /discover HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Content-Length: 14
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "mcc": "214"
        }

        HTTP/1.1 200 OK
        Access-Control-Allow-Credentials: true
        Connection: keep-alive
        Content-Length: 169
        Content-Type: application/json; charset=utf-8
        Date: Mon, 28 Jul 2014 14:18:05 GMT
        Timestamp: 1406557085
        
        {
            "verificationDetails": {
                "sms/momt": {
                    "moVerifier": "+34191600777", 
                    "mtSender": "Mozilla@"
                }
            }, 
            "verificationMethods": [
                "sms/momt"
            ]
        }

    Example (with all parameters)::

      http POST localhost:5000/discover msisdn=+3412578946 mcc=208 mnc=07 --verbose

    .. code-block:: http

        POST /discover HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Content-Length: 51
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "mcc": "214", 
            "mnc": "07", 
            "msisdn": "3412578946"
        }

        HTTP/1.1 200 OK
        Access-Control-Allow-Credentials: true
        Connection: keep-alive
        Content-Length: 286
        Content-Type: application/json; charset=utf-8
        Date: Mon, 28 Jul 2014 14:20:07 GMT
        Timestamp: 1406557207

        {
            "verificationDetails": {
                "sms/momt": {
                    "moVerifier": "+34191600777", 
                    "mtSender": "Mozilla@"
                }, 
                "sms/mt": {
                    "mtSender": "Mozilla@", 
                    "url": "http://localhost:5000/sms/mt/verify"
                }
            }, 
            "verificationMethods": [
                "sms/mt", 
                "sms/momt"
            ]
        }

    Server should return the list of available methods with a
    **200 OK**.

    Potential HTTP error responses include:

    - **400 Bad Request:** The MCC is missing.
    - **429 Too Many Requests:**  Client has sent too many requests
    - **503 Service Unavailable:** Service temporarily unavailable due
      to high load or misconfiguration of the storage backend.


POST /sms/mt/verify
~~~~~~~~~~~~~~~~~~~

    **Requires authentication**

    Starts the SMS MT flow by sending a SMS to the MSISDN to register

    Body parameters:

    - **msisdn**, the Mobile Station ISDN Number that is the user phone number
      to validate in its international form i.e +33623456789.
    - **mcc**, the Mobile Country Code.
    - **mnc**, the Mobile Network Code (optional).
    - **shortVerificationCode**, a parameter to ask a human
      transcribable 6 digits code if set to true. In that case the
      server will also take care of the `Accept-Language` header to
      localize any text in the SMS (optional)

    Response from the server:

    The server should answer this with a **204 No Content** status code.

    Example::

       http POST localhost:5000/sms/mt/verify msisdn=+33123456789 mcc=208 \
           --verbose \
           --auth-type=hawk \
           --auth='8feb2f78227ff8f8d4addd8ba77c06d9ee7acb59d86bd78ae2fd94e242dfd1ee:'

    .. code-block:: http

        POST /sms/mt/verify HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: Hawk mac="THYl...=", hash="mw68...=", id="9ee4...1a81", ts="1406557901", nonce="xoIdtg"
        Content-Length: 53
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0
        
        {
            "mcc": "208", 
            "msisdn": "+33123456789"
        }
        
        HTTP/1.1 204 No Content
        Access-Control-Allow-Credentials: true
        Connection: keep-alive
        Date: Mon, 28 Jul 2014 14:31:41 GMT
        Server-Authorization: Hawk mac="wx9m...=", hash="B0we...="

    Potential HTTP error responses include:

    - **400 Bad Request:** You forgot to give the MSISDN and MCC code
      or pass a wrong MSISDN, MCC or MNC code.
    - **401 Unauthorized**: You need to authenticate to call this URL.
    - **429 Too Many Requests:**  Client has sent too many requests
    - **503 Service Unavailable:** Service temporarily unavailable due
      to high load or misconfiguration of the storage backend.


POST /sms/verify_code
~~~~~~~~~~~~~~~~~~~~~

    **Requires authentication**

    Validates the code received by SMS

    Body parameters:

    - **code**, the code received by SMS.

    Response from the server:

    The server should answer this with a **200 OK** status code and a JSON object
    with the following properties:

    - **msisdn** The Mobile phone number that has been validated during the session.

    Example::

        http POST localhost:5000/sms/verify_code code=15d3b227b0e58f216ee49b8da41c05c8 \
            --verbose \
            --auth-type=hawk \
            --auth='c0d8cd2ec579a3599bef60f060412f01f5dc46f90465f42b5c47467481315f51:'

    .. code-block:: http

        POST /sms/verify_code HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: Hawk mac="8/Rg...=", hash="oAXy...=", id="9ee4...1a81", ts="1406558280", nonce="WBjO3I"
        Content-Length: 44
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0

        {
            "code": "15d3b227b0e58f216ee49b8da41c05c8"
        }

        HTTP/1.1 200 OK
        Access-Control-Allow-Credentials: true
        Connection: keep-alive
        Content-Length: 30
        Content-Type: application/json; charset=utf-8
        Date: Mon, 28 Jul 2014 14:38:00 GMT
        Server-Authorization: Hawk mac="nFOD...=", hash="NVuB...="
        Timestamp: 1406558280

        {
            "msisdn": "+33123456789"
        }

    Potential HTTP error responses include:

    - **400 Bad Request:** code missing or invalid.
    - **401 Unauthorized**: You need to authenticate to call this URL.
    - **429 Too Many Requests:**  Client has sent too many requests
    - **503 Service Unavailable:** Service temporarily unavailable due
      to high load or misconfiguration of the storage backend.


POST /certificate/sign
~~~~~~~~~~~~~~~~~~~~~~

    **Requires authentication**

    Generate a BrowserID certificate with the given public key for the validated number.

    Example::

        http POST localhost:5000/certificate/sign \
            duration=3600 \
            publicKey='{"algorithm":"DS","y":"e6...40","p":"d6...01","q":"b1...3b","g":"9a...ef"}' \
            --verbose \
            --auth-type=hawk \
            --auth='8feb2f78227ff8f8d4addd8ba77c06d9ee7acb59d86bd78ae2fd94e242dfd1ee:'

    .. code-block:: http

        POST /certificate/sign HTTP/1.1
        Accept: application/json
        Accept-Encoding: gzip, deflate
        Authorization: Hawk mac="6vKD...=", hash="PKZT...=", id="9e...81", ts="1406558679", nonce="IFjRIR"
        Content-Length: 1702
        Content-Type: application/json; charset=utf-8
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0
        
        {
            "duration": "3600", 
            "publicKey": "{\"algorithm\":\"DS\",\"y\":\"e6...40\",\"p\":\"d6...01\",\"q\":\"b1...3b\",\"g\":\"9a...ef\"}"
        }

        HTTP/1.1 200 OK
        Access-Control-Allow-Credentials: true
        Connection: keep-alive
        Content-Length: 2602
        Content-Type: application/json; charset=utf-8
        Date: Mon, 28 Jul 2014 14:44:39 GMT
        Server-Authorization: Hawk mac="QMCs...=", hash="NVuB...="
        Timestamp: 1406558679
        
        {
            "cert": "eyJh...1Rgg"
        }

    Potential HTTP error responses include:

    - **400 Bad Request:**  duration or publicKey parameter missing or invalid
    - **401 Unauthorized**: You need to authenticate to call this URL.
    - **429 Too Many Requests:**  Client has sent too many requests
    - **503 Service Unavailable:** Service temporarily unavailable due
      to high load or misconfiguration of the storage backend.


GET /.well-known/browserid
~~~~~~~~~~~~~~~~~~~~~~~~~~

    Returns information for the BrowserID verifier.

    Response from the server:

    The server should answer this with a 200 status code and a JSON object
    with the following properties:

    - **public-key** the server public-key used to validate the BrowserId certificate
    - **authentication**, the link to the authentication page
    - **provisionning**, the link to the provisionning page

    Example::

        http GET localhost:5000/.well-known/browserid --verbose

    .. code-block:: http

        GET /.well-known/browserid HTTP/1.1
        Accept: */*
        Accept-Encoding: gzip, deflate
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0


        HTTP/1.1 200 OK
        Access-Control-Allow-Credentials: true
        Connection: keep-alive
        Content-Length: 1815
        Content-Type: application/json; charset=utf-8
        Date: Mon, 28 Jul 2014 14:54:50 GMT
        ETag: W/"717-781509924"
        Timestamp: 1406559290

        {
            "authentication": "/.well-known/browserid/warning.html", 
            "provisioning": "/.well-known/browserid/warning.html", 
            "public-key": {
                "algorithm": "DS", 
                "g": "9a...ef", 
                "p": "d6...01", 
                "q": "b1...3b", 
                "y": "7e...b9"
            }
        }


GET /api-specs
~~~~~~~~~~~~~~

    An endpoint that gives back the videur configuration.

    Server should answer with a status of 200 and the API routes as a JSON object.

    Example::

        http GET localhost:5000/api-specs --verbose

    .. code-block:: http

        GET /api-specs HTTP/1.1
        Accept: */*
        Accept-Encoding: gzip, deflate
        Host: localhost:5000
        User-Agent: HTTPie/0.8.0


        HTTP/1.1 200 OK
        Access-Control-Allow-Credentials: true
        Connection: keep-alive
        Content-Length: 1069
        Content-Type: application/json; charset=utf-8
        Date: Mon, 28 Jul 2014 14:57:54 GMT
        ETag: W/"42d-3425668954"
        Timestamp: 1406559474
        
        {
            "service": {
                "location": "http://localhost:5000", 
                "resources": {
                    "/": {
                        "GET": {}
                    }, 
                    "/.well-known/browserid": {
                        "GET": {}
                    }, 
                    "/.well-known/browserid/warning.html": {
                        "GET": {}
                    }, 
                    "/__heartbeat__": {
                        "GET": {}
                    }, 
                    "/certificate/sign": {
                        "POST": {
                            "max_body_size": "10k"
                        }
                    }, 
                    "/discover": {
                        "POST": {
                            "max_body_size": "10k"
                        }
                    }, 
                    "/register": {
                        "POST": {
                            "max_body_size": "10k"
                        }
                    }, 
                    "/sms/momt/beepsend_callback": {
                        "GET": {}
                    }, 
                    "/sms/momt/nexmo_callback": {
                        "GET": {}
                    }, 
                    "/sms/mt/verify": {
                        "POST": {
                            "max_body_size": "10k"
                        }
                    }, 
                    "/sms/verify_code": {
                        "POST": {
                            "max_body_size": "10k"
                        }
                    }, 
                    "/unregister": {
                        "POST": {
                            "max_body_size": "10k"
                        }
                    }
                }, 
                "version": "0.5.0", 
                "videur_version": "0.1"
            }
        }


SMS /sms/momt/verify
~~~~~~~~~~~~~~~~~~~~

    The SMS message to a moVerifier number will start the MOMT flow.

    SMS should be of the form of:

        /sms/momt/verify <hawkId>

    i.e::

        /sms/momt/verify 9ee442e5c8575c4077db786a40f603a70ae8eee09f5b41e34c096410f6fc1a81

    - **path**, future proof path, in order to be able to route SMS to the right endpoint.
    - **hawkId**, the hawk session id extracted from the `msisdnSessionToken` using HKDF.

    When the SMS Gateway receive the Inbound Message, it will make a
    call on the configured endpoint.

    **For Nexmo** — GET /sms/momt/nexmo_callback

    Querystring parameters:

    - **msisdn**, the phone number from which the message is coming
    - **text**, the content of the message
    - **network-code**, the MCC/MNC unique identifier

    **For BeepSend** — GET /sms/momt/nexmo_callback

    Querystring parameters:

    - **from**, the phone number from which the message is coming
    - **message**, the content of the message


Error Responses
---------------

All errors are also returned, wherever possible, as json responses
with a code, errno and error message.

Error status codes and codes and their corresponding outputs are:

- **404** : unknown URL or unsupported application.
- **400** : malformed request. Possible causes include a missing
  option, bad values or malformed json.
- **401** : you need to be authenticated
- **403** : you are authenticated but don't have access to the resource you are
            requesting.
- **405** : unsupported method
- **406** : unacceptable - the client asked for an Accept we don't support
- **503** : service unavailable (provider or database backends may be down)

Also the associated errno can be one of:

- **105 INVALID_CODE**: This come with a 404 on a wrong validation code;
- **106 BADJSON**: This come with a 406 if the sent JSON is not parsable;
- **107 INVALID_PARAMETERS**: This come with a 400 and describe invalid parameters with a reason;
- **108 MISSING_PARAMETERS**: This come with a 400 and list all missing parameters;
- **109 INVALID_REQUEST_SIG**: This come with a 401 and define a problem with the Hawk hash;
- **110 INVALID_AUTH_TOKEN**: This come with a 401 and define a problem during Auth;
- **111 EXPIRED**: This come with a 410 and define a EXPIRE ressource;
- **112 LENGTH_MISSING**: This come with a 411 and defined a missing Content-Length header.
- **113 REQUEST_TOO_LARGE**: This come with a 400 and define a too large request;
- **201 BACKEND**: This come with a 503 when a third party is not available at the moment.
