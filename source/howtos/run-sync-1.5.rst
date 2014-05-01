.. _howto_run_sync15:

============================
Run your own Sync-1.5 Server
============================

The Firefox Sync Server is deployed on our systems using RPM packaging,
and we don't provide any other packaging or publish official RPMs yet.

The easiest way to install a Sync Server is to checkout our repository
and run a build in-place. Once this is done, Sync can be run behind
any Web Server that supports the :term:`WSGI` protocol.

.. note:: These instructions are for the sync-1.5 server protocol used by
   the `new sync service <https://wiki.mozilla.org/User_Services/Sync>`_  in
   Firefox 29 and later.  For a server compatible with earlier versions of
   Firefox, see :ref:`howto_run_sync11`.

.. note:: This guide is preliminary and vastly incomplete.  It will be fleshed
      out as development progresses and as the first Firefox-Accounts-enabled
   version of Firefox moves closer to stable release.


Prerequisites
=============

The various parts are using **Python 2.7** and **Virtualenv**. Make sure your
system has them, or install them:

- Python 2.7 downloads: http://python.org/download/releases/2.7.6
- Virtualenv: http://pypi.python.org/pypi/virtualenv

To build and run the server, you will also need to have these packages
installed:

- python-dev
- make
- git

For example, under a fresh Ubuntu, you can run this command to meet all
requirements::

    $ sudo apt-get install python-dev git-core python-virtualenv


Building the server
===================

Get the latest version at https://github.com/mozilla-services/syncserver and
run the **build** command::

    $ git clone https://github.com/mozilla-services/syncserver
    $ cd syncserver
    $ make build

This command will create an isolated Python environment and pull all the
required dependencies in it. A **local/bin** directory is created and contains
a **pserve** command that can be used to run the server, using the built-in web
server.

If you like, you can run the testsuite to make sure everything is working
properly::

    $ make test


Basic Configuration
===================

The server is configured using an ini-like file to specify various runtime
settings.  The file "syncserver.ini" will provide a useful starting point.

There is one setting that you *must* specify before running the server: the
client-visible URL for the service.  Open "etc/sync.conf" and locate the
following lines::

    [syncserver]
    public_url = http://localhost:5000/

The default value of "public_url" will work for testing purposes on your local
machine.  For final deployment, change it to the external, publicly-visible URL
of your server.

By default the server will use an in-memory database for storage, meaning that
any sync data will be lost on server restart.  You will almost certainly want
to configure a more permanent database, which can be done with the "sqluri"
setting::

    [syncserver]
    sqluri = sqlite:////path/to/database/file.db

This setting will accept any `SQLAlchemy <http://www.sqlalchemy.org/>`_
database URI; for example the following would connect to a mysql server::

    [syncserver]
    sqluri = pymysql://username:password@db.example.com/sync


Running the Server
==================

Now you can run the server using pserve and the provided "syncserver.ini"
file::

    $ local/bin/pserve syncserver.ini
    Starting server in PID 29951.
    serving on 0.0.0.0:5000 view at http://127.0.0.1:5000

Once the server is launched, you need to tell Firefox about its location.
Go to "about:config", search for "services.sync.tokenServerURI" and change
its value to the URL of your server with a path of "token/1.0/sync/1.5":

  - services.sync.tokenServerURI:  http://sync.example.com/token/1.0/sync/1.5


Updating the server
===================

You should periodically update your code to make sure you've got the latest
fixes.  The following commands will update syncserver in place::

    $ cd /path/to/syncserver
    $ git stash       # to save any local changes to the config file
    $ git pull        # to fetch latest updates from github
    $ git stash pop   # to re-apply any local changes to the config file
    $ make build      # to pull in any updated dependencies


Running behind a Web Server
===========================

The built-in server should not be used in production, as it does not really
support a lot of load.

If you want to set up a production server, you can use different web servers
that are compatible with the WSGI protocol. For example:

- *Apache* combined with *mod_wsgi*
- *NGinx* with *Gunicorn* or *uWSGI*


.. note:: Remember, you must set the **syncserver.public_url** option to the
   client-visible URL of your server.

   For example, if your server will be located at http://example.com/ff-sync/,
   the public_url should be set to this value in your config file::

       [syncserver]
       public_url = http://example.com/ff-sync/


Apache + mod_wsgi
:::::::::::::::::

Here's an example of an Apache 2.2 setup that uses mod_wsgi::

  <Directory /path/to/syncserver>
    Order deny,allow
    Allow from all
  </Directory>

  <VirtualHost \*:80>
    ServerName example.com
    DocumentRoot /path/to/syncserver
    WSGIProcessGroup sync
    WSGIDaemonProcess sync user=sync group=sync processes=2 threads=25 python-path=/path/to/syncserver/local/lib/python2.7/site-packages/
    WSGIPassAuthorization On
    WSGIScriptAlias / /path/to/syncserver/sync.wsgi
    CustomLog /var/log/apache2/example.com-access.log combined
    ErrorLog  /var/log/apache2/example.com-error.log
  </VirtualHost>

Here's the equivalent setup for Apache 2.4, which uses a different syntax
for access control::

  <Directory /path/to/syncserver>
    Require all granted
  </Directory>

  <VirtualHost \*:80>
    ServerName example.com
    DocumentRoot /path/to/syncserver
    WSGIProcessGroup sync
    WSGIDaemonProcess sync user=sync group=sync processes=2 threads=25 python-path=/path/to/syncserver/local/lib/python2.7/site-packages/
    WSGIPassAuthorization On
    WSGIScriptAlias / /path/to/syncserver/sync.wsgi
    CustomLog /var/log/apache2/example.com-access.log combined
    ErrorLog  /var/log/apache2/example.com-error.log
  </VirtualHost>

We provide a **syncserver.wsgi** file for your convenience in the repository.
Before running Apache, edit the file and check that it loads the the right
.ini file with its full path.


Nginx + Gunicorn
::::::::::::::::

Tested with debian stable/squeeze

1. First install gunicorn in the syncserver python environment

        $ cd /usr/src/syncserver
        $ bin/easy_install gunicorn

2. Then enable gunicorn in the **syncserver.ini** file::

        [server:main]
        use = egg:gunicorn
        host = 127.0.0.1
        port = 5000
        workers = 2
        timeout = 60

3. Finally edit your nginx vhost file::

        server {
                listen  443 ssl;
                server_name sync.example.com;

                ssl_certificate /path/to/your.crt;
                ssl_certificate_key /path/to/your.key;

                location / {
                        proxy_set_header Host $http_host;
                        proxy_set_header X-Forwarded-Proto $scheme;
                        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                        proxy_set_header X-Real-IP $remote_addr;
                        proxy_redirect off;
                        proxy_read_timeout 120;
                        proxy_connect_timeout 10;
                        proxy_pass http://127.0.0.1:5000/;
                        }
                }

5. After restarting your nginx and syncserver you should be able to use the
   sync server behind your nginx installation


Things that stil need to be Documented
======================================

* how to restrict new-user signups
* how to interoperate with a self-hosted accounts server
* periodic pruning of expired sync data


Asking for help
===============

Don't hesitate to jump online and ask us for help:

- on IRC (irc.mozilla.org) in the #sync channel
- in our Mailing List: https://mail.mozilla.org/listinfo/services-dev
