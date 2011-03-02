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


cef
---

The *cef* library implements a CEF logger.

Most Services applications need to generate CEF logs. A CEF Log is a
formatted log that can be used by ArcSight, a central application used
by the infrasec team to manage application security.

The *cef* module provides a :func:`log_cef` function that can be 
used to emit CEF logs:

    log_cef(message, severity, environ, config, [username,
            [signature]], \*\*kw)

    Creates a CEF record, and emit it in syslog or another file.

    Args:
        - message: message to log
        - severity: integer from 0 to 10
        - environ: the WSGI environ object
        - config: configuration dict
        - signature: CEF signature code, defaults to 'AuthFail'
        - username: user name, defaults to 'none'
        - extra keywords: extra keys used in the CEF extension

Example::

    >>> from cef import log_cef
    >>> log_cef('SecurityAlert!', 5, environ, config,
    ...         msg='Someone has stolen my chocolate')


With *environ* and *config* provided by the web environment.

Note that the CEF library is published at PyPI.

See :ref:`config-cef` for more info on this.


server-core
-----------

The *server-core* library provides helpers to build Services applications:

- a configuration reader.
- a base WSGI application, `SyncServerApp`.
- various utilities for web applications but also for lower level needs.


Configuration files
,,,,,,,,,,,,,,,,,,,

The configuration files we use in Services applications are based on an
extended version of Ini files. You can find a description of the file
at https://wiki.mozilla.org/Services/Sync/Server/GlobalConfFile.

Example of usage::

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
  and a 503s is raised.
- a heartbeat page useful for monitoring the server
- a few middlewares integrated: a profiler, an error catcher
  and a console logger.

XXX

Misc
,,,,

XXX


