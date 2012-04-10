========================================
Overview of Services Python applications
========================================

Services Python applications are all :term:`WSGI` applications based on the same
stack of tools::


    NGinx <= TCP => Gunicorn <= WSGI => SyncServerApp <=> WebOb


- `NGinx <http://nginx.net>`_ : A high-speed HTTP Server/reverse proxy.
- `GUnicorn <http://gunicorn.org>`_: A Python WSGI Server.
- SyncServerApp: A base WSGI application for all Services apps. Located
  in the `server-core <http://hg.mozilla.org/services/server-core>`_
  repository.
- `WebOb <http://pythonpaste.org/webob>`_: a Request and a Response object
  with a simple interface.


Services provides two base libraries to build WSGI applications:

- **cef**: implements a CEF logger for ArcSight.
- **server-core**: provides helpers to build Services applications.


cef
---

Most Services applications need to generate CEF logs. A CEF Log is a
formatted log that can be used by ArcSight, a central application used
by the Infrasec team to manage application security.

The *cef* module provides a :func:`log_cef` function that can be 
used to emit CEF logs:

    log_cef(message, severity, environ, config, [username, [signature]], \*\*kw)

    Creates a CEF record, and emits it in syslog or another file.

    Args:
        - message: message to log
        - severity: integer from 0 to 10
        - environ: the WSGI environ object
        - config: configuration dict
        - username: user name, defaults to 'none'
        - signature: CEF signature code, defaults to 'AuthFail'
        - extra keywords: extra keys used in the CEF extension

Example::

    >>> from cef import log_cef
    >>> log_cef('SecurityAlert!', 5, environ, config,
    ...         msg='Someone has stolen my chocolate')


With *environ* and *config* provided by the web environment.

Note that the CEF library is published at PyPI: http://pypi.python.org/pypi/cef

See :ref:`config-cef` for more info on this.


server-core
-----------

The *server-core* library provides helpers to build Services applications.

In *server-core*'s philosophy, a WSGI application is a :class:`SyncServerApp` 
instance which will contain a **config** attribute that's a mapper containing
all the configuration needed by the code. This configuration 
is loaded from a unique ini-like file.

When a request comes in, *Routes* is used to dispatch it to a controller 
method.

Controllers are simple classes whose methods receive the request and
need to return a response.


Configuration files
,,,,,,,,,,,,,,,,,,,

The configuration files we use in Services applications are based on an
extended version of Ini files. You can find a description of the file
at https://wiki.mozilla.org/Services/Sync/Server/GlobalConfFile.

*server-core* provides a simple reader::

    >>> from services.config import Config
    >>> cfg = Config('/etc/keyexchange/keyexchange.conf')
    >>> cfg.sections()
    ['keyexchange', 'filtering', 'cef']

    >>> cfg.items('keyexchange')
    [('max_gets', 10), ('root_redirect', 'https://services.mozilla.com'),
     ('use_memory', False), ('ttl', 300),
     ('cache_servers', ['127.0.0.1:11211']), ('cid_len', 4)]

    >>> cfg.get('keyexchange', 'cid_len')
    4


Note that :class:`SyncServerApp` will automatically create a Config instance
over a central configuration file when it's used to create a web application.

See :ref:`config-file` for more info on this.


SyncServerApp
,,,,,,,,,,,,,

The :class:`SyncServerApp` is a base class that can be used to get a few
automation and some useful helpers when you want to create an application
for Services.

It provides:

- a central configuration file
- a pluggable authentication backend with an LDAP and an SQL
  plugin provided.
- an overridable authentication process, defaulting to
  :term:`Basic Authentication`.
- a basic URL dispatcher based on Routes.
- an error handler that ensures backend errors are logged
  and a 500 error is raised.
- a heartbeat page useful for monitoring the server
- a debug page to display useful information on the server
- a few middlewares integrated: a profiler, an error catcher
  and a console logger.

To create an application using :class:`SyncServerApp`, see :ref:`complete-layout`.

