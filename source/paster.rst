==================
Configuring Paster
==================

The server is launched using Paster Deploy, which reads an ini-like file 
that defines among other things:

- where the wsgi application is located
- where the application configuration is located
- the logging configuration
- etc.


DEFAULT
=======

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
===========

Defines the web server to use to run the app with Paster. See Paster 
documentation for more info.

Example::

    [server:main]
    use = egg:Paste#http
    host = 0.0.0.0
    port = 5000
    use_threadpool = True
    threadpool_workers = 60

app:main
========

Defines the server entry point. See Paster documentation for more info.

**configuration** can point to a configuration file for the server. It uses a *file:* prefix. 

Example::

    [app:main]
    use = egg:SyncServer
    configuration = file:%(here)s/etc/sync.conf

logging
=======

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

profile
=======

Activates the **repoze.profile** middleware.

XXX
