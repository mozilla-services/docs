===========================
Configuring the application
===========================

The application is configured via two files:

- the Paster ini-like file, located in etc/
- the Services configuration file.


XXX more on file ocation


Paster ini file
===============

All Services projects provide a built-in web server that may be used to
run a local instance.

For example in *server-full*, once the project is built, you can run it::

    $ bin/paster serve development.ini

This will run a server on port 5000.


Paster reads an ini-like file that defines among other things:

- where the wsgi application is located
- where the application configuration is located
- the logging configuration
- etc.

The main sections we want to configure in this file are:

- DEFAULT
- server:main
- app:main
- logging


DEFAULT
-------

The default section defines four optional values (all are set to False by 
default):

1. **debug**: if set to True, will activate the debug mode.
2. **client_debug**: if set to True, will return in the body of the response 
   any traceback when a 500 occurs.
3. **translogger**: will display in the stdout all requests made on the server.
4. **profile**: will activate a profiler and generate cachegrind infos.

Example::

    [DEFAULT]
    debug = True
    translogger = False
    profile = False


server:main
-----------


Defines the web server to use to run the app with Paster. See Paster 
documentation for more info.

Example::

    [server:main]
    use = egg:Paste#http
    host = 0.0.0.0
    port = 5000
    use_threadpool = True
    threadpool_workers = 60

.. _config-app-main:

app:main
--------

Defines the server entry point. See Paster documentation for more info.

**configuration** can point to a configuration file for the server. 
It uses a *file:* prefix. 


Example::

    [app:main]
    use = egg:SyncServer
    configuration = file:%(here)s/etc/sync.conf


logging
-------

Logging is done using the logging configuration. See Python's logging 
documentation for more details.

The Sync server uses the **syncserver** logger everywhere.

In the following example, all Sync errors are logged in a specific file 
as long as **DEFAULT:debug** is activated. Other logs are in 
a separate file.::

    [loggers]
    keys = root,syncserver

    [handlers]
    keys = global,errors

    [formatters]
    keys = generic

    [logger_root]
    level = WARNING
    handlers = global

    [logger_syncserver]
    qualname = syncserver
    level = INFO
    handlers = global, errors
    propagate = 0

    [handler_global]
    class = handlers.RotatingFileHandler
    args = ('/var/log/sync.log',)
    level = DEBUG
    formatter = generic

    [handler_errors]
    class = handlers.RotatingFileHandler
    args = ('/var/log/sync-error.log',)
    level = ERROR
    formatter = generic

    [formatter_generic]
    format = %(asctime)s,%(msecs)03d %(levelname)-5.5s [%(name)s] %(message)s
    datefmt = %Y-%m-%d %H:%M:%S


.. _profile-config:

Configuring the profiler
------------------------

Activates the **repoze.profile** middleware.

XXX


.. _config-file:

Configuration file
==================

The server uses a global configuration :file:`sync.conf` file.
The file location is configured in the Paster ini file and loaded when
the application starts. See :ref:`config-app-main`.

The configuration file has one section for each service provided by the
application.


Global
------

Global settings for the applications, under the **global** section.

Available options (o: optional, m: multi-line, d: default):

- **retry_after** [o, default:1800]: Value in seconds of the Retry-After
  header sent back when a 503 occurs in the application.

- **heartbeat_page** [o, default:__heartbeat__]: defines the path of 
  the heartbeat page. The heartbeat page is used by an HTTP Monitor to
  check that the server is still running properly. It returns a 200 if 
  everything works, and a 503 if there's an issue. A Typical issue is 
  the inability for the application to reach a backend server, like 
  MySQL or OpenLDAP.

- **debug_page** [o, default:None]: defines the path of the debug page.
  The debug page displays environ information. 

  **Warning**: This page may expose private data. Once activated,
  it is not password-protected. If you use it, make sure the web server 
  (Apache, Nginx) protects it from anonymous access.

  This feature is disabled by default to avoid any security issue.


Example::

    [global]
    retry_after = 60
    heartbeat_page = __another_heartbeat_url_
    debug_page = __debug__


Storage
-------


The storage section is **storage**. It contains everything neeed by the
storage server to read and write data.

Available options (o: optional, m: multi-line, d: default):

- **backend**: backend used for the storage. Existing backends :
  **sql**, **memcached**.
- **cache_servers** [o, m]: list of memcached servers (host:port)
- **sqluri**: uri for the DB. see RFC-1738 for the format.
  *driver://username:password@host:port/database*. Supported drivers are: sqlite,
  postgres, oracle, mssql, mysql, firebird
- **standard_collections** [o, default: true]: if set to true, the server will
  use hardcoded values for collections.
- **use_quota** [o, default:false]: if set to false, users will not have any quota.
- **quota_size** [o, default:none]: quota size in KB
- **pool_size** [o, default:100]: define the size of the SQL connector pool.
- **pool_recycle** [o, default:3600]: time in ms to recycle a SQL connection that was closed.


Example::

    [storage]

    backend = memcached
    cache_servers = 127.0.0.1:11211
                    192.168.1.13:11211

    sqluri = mysql://sync:sync@localhost/sync
    standard_collections = false
    use_quota = true
    quota_size = 5120
    pool_size = 100
    pool_recycle = 3600



Authentication
--------------


The authentication section is **auth**. It contains everything needed for 
authentication and registration.

Available options (o: optional, m: multi-line, d: default):

- **backend**: backend used for the storage. Existing backends :
  **sql**, **ldap**, **dummy**.
- **ldapuri** [o]: uri for the LDAP server when the ldap backend is used.
- **ldaptimeout** [o, default:-1]: maximum time in secondes allowed for a
  LDAP query. -1 means no timeout.
- **use_tls** [o, default:false]: If set to true, activates TLS when using
  LDAP.
- **bind_user** [o, default:none]: user for common LDAP queries.
- **bind_password** [o, default:none]: password for the bind user.
- **admin_user** [o, default:none]: user with extended rights for write
  operations.
- **admin_password** [o, default:none]: password for the admin user.
- **users_root** [o, default:none]: root for all ldap users. If set to *md5*
  will generate a specific location based on the md5 hash of the
  user name.
- **cache_servers** [o, m]: list of memcached servers (host:port)
- **sqluri**: uri for the DB. see RFC-1738 for the format.
  *driver://username:password@host:port/database*. Supported drivers are: sqlite,
  postgres, oracle, mssql, mysql, firebird
- **pool_size** [o, default:100]: define the size of the SQL connector pool.
- **pool_recycle** [o, default:3600]: time in ms to recycle a SQL connection that was closed.


Example::

    [auth]
    backend = ldap
    ldapuri = ldap://localhost:390
    ldap_timeout =  -1
    use_tls = false

    bind_user = "cn=admin,dc=mozilla"
    bind_password = admin

    admin_user = "cn=admin,dc=mozilla"
    admin_password = admin

    users_root = "ou=users,dc=mozilla"

    sqluri = mysql://sync:sync@localhost/sync
    pool_size = 100
    pool_recycle = 3600

    cache_servers = 127.0.0.1:11211



Captcha
-------

The **captcha** section enables the re-captcha feature during user
registration.

Available options (o: optional, m: multi-line, d: default):

- **use**: if set to false, all operations will be done w/ captcha.
- **public_key**: public key for reCaptacha.
- **private_key**: private key for reCaptacha.
- **use_ssl**: if set to true, will use SSL when connection to recaptcha.

Example::

    [captcha]
    use = true
    public_key = 6Le8OLwSAAAAAK-wkjNPBtHD4Iv50moNFANIalJL
    private_key = 6Le8OLwSAAAAAEKoqfc-DmoF4HNswD7RNdGwxRij
    use_ssl = false


SMTP
----

The **smtp** section configures the SMTP connection used by the application to
send e-mails.

Available options (o: optional, m: multi-line, d: default):

- **host** [o, default:localhost]: SMTP host
- **port** [o, default:25]: SMTP port
- **username** [o, default:none]: SMTP user
- **password** [o, default:none]: SMTP password
- **sender** [o]: E-mail used for the sender field.

Example::

    [smtp]
    host = localhost
    port = 25
    sender = weave@mozilla.com

.. _config-cef:

CEF
---

The **cef** section configues how CEF security alerts are emited.

Available options (o: optional, m: multi-line, d: default):

- **use**: if set to true, CEF alerts are emited.
- **file**: location of the CEF log file. Can be a file path
  or *syslog* to use the syslog facility.
- **syslog.options** [o, default:none]: comma-separated values for syslog.
  Authorized values are: PID, CONS, NDELAY, NOWAIT, PERROR
- **syslog.priority** [o, default:INFO]: priority level.
  Authorized value: EMERG, ALERT, CRIT, ERR, WARNING, NOTICE, INFO, DEBUG.
- **syslog.facility** [o, default:LOCAL4]: facility
  Authorized values: KERN, USER, MAIL, DAEMON, AUTH, LPR, NEWS, UUCP, CRON
  and LOCAL0 to LOCAL7.
- **vendor**: CEF-specific option.
- **version**: CEF-specific option.
- **device_version**: CEF-specific option.
- **product**: CEF-specific option.

Example::

    [cef]
    use = true
    file = syslog

    syslog.options = PID,CONS
    syslog.priority = DEBUG
    syslog.facility = USER

    vendor = mozilla
    version = 0
    device_version = 1.3
    product = weave

 

