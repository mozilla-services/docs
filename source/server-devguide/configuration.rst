.. _configuration:

===========================
Configuring the application
===========================

The application is configured via two files:

- the Paster ini-like file, located in etc/
- the Services configuration file.


XXX more on file location


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
a separate file::

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

The server uses a global configuration file.  The file location is configured
in the Paster ini file (as the `configuration` setting in the `[app:main]`
section), and it is loaded when the application starts. See
:ref:`config-app-main`.

The configuration file has one section for each module loaded by the
application.  The configuration data will be available on the application
object as a dictionary-like object stored in the `config` attribute.  The
settings from the `[global]` section will be stored as the simple key name,
while the settings from the other sections will be keyed as
`<section_name>.<key>`.

So::

    [global]
    foo = bar
    baz = bawlp

    [storage]
    bing = boom

    [auth]
    snaf = foo

Would produce the following `app.config`::

    {'foo': 'bar',
     'baz': 'bawlp',
     'storage.bing': 'boom',
     'auth.snaf': 'foo'}

Additionally, `config.get_section` will return a dictionary containing
only the settings from the specified section, without the prefix.  So
continuing the example above...

`app.config.get_section('global')` would return::

    {'foo': 'bar',
     'baz': 'bawlp'}

`app.config.get_section('storage')` would return::

    {'bing': 'boom}



Multi-Config Sections
---------------------

In addition to supporting standard "INI" file conventions, Server-Core based
applications provide an ability to use namespaced section headers to allow for
multiple, similar variations of a config section to be registered
simultaneously.

The storage service used by the sync server is an example of where this is
useful.  Each storage server instance is associated with a specific set of back
end storage nodes, usually all of the nodes that are located in the same
location as the storage server itself.  The storage server loads a separate
configuration for each storage node, all similar save for the database
connection URL.

Example::

    [storage]
    backend = memcached
    cache_servers = 127.0.0.1:11211
                    192.168.1.13:11211
    sqluri = mysql://localhost/sync
    standard_collections = false
    use_quota = true
    quota_size = 5120
    pool_size = 100
    pool_recycle = 3600

    [host:node0]
    storage.sqluri = mysql://sync:sync@db1.example.com/sync

    [host:node1]
    storage.sqluri = mysql://sync:sync@db1.example.com/sync

    [host:node2]
    storage.sqluri = mysql://sync:sync@db2.example.com/sync

    [host:node3]
    storage.sqluri = mysql://sync:sync@db2.example.com/sync

The generated config object would then have sections named `storage`,
`host:node0`, `host:node1`, etc., as you might expect.  In addition to being
available as separate sections, however, these configurations can be merged
with the sections they refer to to generate "override" configs.  These are made
avaialable via the `merge(*sections)` method on the config object.

So, `app.config` would produce::

    {'storage.backend': 'memcached',
     'storage.cache_servers': ['127.0.0.1:11211', '192.168.1.13:11211'],
     'storage.sqluri': 'mysql://localhost/sync',
     'storage.standard_collections': False,
     'storage.use_quota': True,
     'storage.quota_size': 5120,
     'storage.pool_size': 100,
     'storage.pool_recycle': 3600,
     'host:node0.storage.sqluri': 'mysql://sync:sync@db1.example.com/sync',
     'host:node1.storage.sqluri': 'mysql://sync:sync@db1.example.com/sync',
     'host:node2.storage.sqluri': 'mysql://sync:sync@db2.example.com/sync',
     'host:node3.storage.sqluri': 'mysql://sync:sync@db2.example.com/sync',
     }

while `app.config.merge('host:node0')` would give::

    {'storage.backend': 'memcached',
     'storage.cache_servers': ['127.0.0.1:11211', '192.168.1.13:11211'],
     'storage.standard_collections': False,
     'storage.use_quota': True,
     'storage.quota_size': 5120,
     'storage.pool_size': 100,
     'storage.pool_recycle': 3600,
     'storage.sqluri': 'mysql://sync:sync@db1.example.com/sync',
     'host:node0.storage.sqluri': 'mysql://sync:sync@db1.example.com/sync',
     'host:node1.storage.sqluri': 'mysql://sync:sync@db1.example.com/sync',
     'host:node2.storage.sqluri': 'mysql://sync:sync@db2.example.com/sync',
     'host:node3.storage.sqluri': 'mysql://sync:sync@db2.example.com/sync',
     }


Global
------

Global settings for the applications, under the **global** section.

Available options (o: optional, m: multi-line, d: default):

- **retry_after** [o, default:1800]: Value in seconds of the Retry-After
  header sent back when a 503 occurs in the application.

- **heartbeat_page** [o, default:__heartbeat__]: defines the path of
  the heartbeat page. The heartbeat page is used by an HTTP Monitor to
  check that the server is still running properly. It returns a 200 if
  everything works, and a 503 if there's an issue. A typical issue is
  the inability for the application to reach a backend server, like
  MySQL or OpenLDAP.

- **debug_page** [o, default:None]: defines the path of the debug page.
  The debug page displays environ information.

  **Warning**: This page may expose private data. Once activated,
  it is not password-protected. If you use it, make sure the web server
  (Apache, Nginx) protects it from anonymous access.

  This feature is disabled by default to avoid any security issue.

- **shared_secret** [o, default: None]: defines a secret string that
  can be used by the client when creating users, to bypass the
  captcha challenge.

- **graceful_shutdown_interval** [o, default: 1]: Number of seconds before the
  app starts to shutdown. New requests are still accepted but the heartbeat
  page starts to return 503.

- **hard_shutdown_interval** [o, default: 1]: Number of seconds before the app
  is shut down. Any new call returns a 503, and pending requests have that time
  to finish up the work before the app dies.

  Notice that an event is triggered when the process ends, giving a chance for
  apps to cleanup things.


Example::

    [global]
    retry_after = 60
    heartbeat_page = __another_heartbeat_url_
    debug_page = __debug__


Storage
-------


The storage section is **storage**. It contains everything needed by the
storage server to read and write data.

Available options (o: optional, m: multi-line, d: default):

- **backend**: backend used for the storage. Takes the fully qualified
  name of the class.

  Existing backends :

  - **syncstorage.storage.sql.SQLStorage**
  - **syncstorage.storage.memcached.MemcachedSQLStorage**.

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

- **backend**: backend used for the storage.

  Existing backends :

  - **services.auth.sql.SQLAuth**
  - **services.auth.ldap.LDAPAuth**
  - **services.auth.dummy.DummyAuth**

- **ldapuri** [o]: uri for the LDAP server when the ldap backend is used.
- **ldap_use_pool** [o, default:False]: If True, a pool of connectors is used.
- **ldap_pool_size** [o, default:10]: Size of the ldap pool when used.
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
    ldap_use_pool = true
    ldap_pool_size = 100

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

- **use**: if set to false, all operations will be done without captcha.
- **public_key**: public key for reCaptcha.
- **private_key**: private key for reCaptcha.
- **use_ssl**: if set to true, will use SSL when connecting to reCaptcha.

Example::

    [captcha]
    use = true
    public_key = 6Le8OLwSAAAAAK-wkjNPBtHD4Iv50moNFANIalJL
    private_key = 6Le8OLwSAAAAAEKoqfc-DmoF4HNswD7RNdGwxRij
    use_ssl = false

.. warning::

    The keys provided in this example work, as they were generated to provide
    a realistic example. But do not use them in your applications.

    Instead, you should generate a new set of keys for you own domain.

    See: https://www.google.com/recaptcha/admin/create



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

The **cef** section configures how CEF security alerts are emitted.

Available options (o: optional, m: multi-line, d: default):

- **use**: if set to true, CEF alerts are emitted.
- **file**: location of the CEF log file. Can be a file path
  or *syslog* to use the syslog facility.
- **syslog.options** [o, default:none]: comma-separated values for syslog.
  Authorized values are: PID, CONS, NDELAY, NOWAIT, PERROR
- **syslog.priority** [o, default:INFO]: priority level.
  Authorized values: EMERG, ALERT, CRIT, ERR, WARNING, NOTICE, INFO, DEBUG.
- **syslog.facility** [o, default:LOCAL4]: facility.
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

