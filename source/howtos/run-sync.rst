.. _howto_run_sync11:

============================
Run your own Sync-1.1 Server
============================

The Firefox Sync Server is deployed on our systems using RPM packaging,
and we don't provide any other packaging or publish official RPMs yet.

The easiest way to install a Sync Server is to checkout our repository
and run a build in-place. Once this is done, Sync can be run behind
any Web Server that supports the :term:`WSGI` protocol.

.. note:: These instructions are for the sync server protocol used by Firefox
   28 and earlier.  Firefox 29 and later include a `new sync service
   <https://wiki.mozilla.org/User_Services/Sync>`_ that is incompatible with
   this server.  For a server compatible with Firefox 29 and later, see
   :ref:`howto_run_sync15`.


Prerequisites
=============

The various parts are using **Python 2.6** and **Virtualenv**. Make sure your
system has them. Or install them:

- Python 2.6 downloads: http://python.org/download/releases/2.6.6
- Virtualenv: http://pypi.python.org/pypi/virtualenv

To run the server, you will also need to have these packages installed:

- python-dev
- make
- mercurial
- sqlite3
- openssl-dev

For example, under a fresh Ubuntu, you can run this command to meet all
requirements::

    $ sudo apt-get install python-dev mercurial sqlite3 python-virtualenv libssl-dev


Building the server
===================

Get the latest version at https://hg.mozilla.org/services/server-full and
run the **build** command::

    $ hg clone https://hg.mozilla.org/services/server-full
    $ cd server-full
    $ make build

This command will create an isolated Python environment and pull all the
required dependencies in it. A **bin** directory is created and contains a
**paster** command that can be used to run the server, using the built-in web
server.


.. note:: Occasionally the build may fail due to network issues that make
   PyPI inaccessible.  If you receive an error about "Could not find suitable
   distribution", try waiting a little while and then running the build again.


If you like, you can run the testsuite to make sure everything is working
properly::

    $ make test

If this gives you an error about "pysqlite2", you may need to install the
"pysqlite" package like so::

    $ ./bin/pip install pysqlite


Basic Configuration
===================

The server is configured using an ini-like file to specify various
runtime settings.  The file "etc/sync.conf" will provide a useful starting
point".

There is one setting that you *must* specify before running the server: the
client-visible URL for the storage service node.  To ensure that the :ref:`reg`
and Node-Assignment flow works correctly, this should be set to the URL at
which you will be running the server.

Open "etc/sync.conf", locate and uncomment the following lines::

    [nodes]
    fallback_node = http://localhost:5000/

By default the server is configured to use a SQLite database for the storage
and the user APIs, with the database file stored at "/tmp/test.db".  You will
almost certainly want to change this to a more permanent location::

    [storage]
    sqluri = sqlite:////path/to/database/file.db

    [auth]
    sqluri = sqlite:////path/to/database/file.db

Alternatively, consider using a different database backend as described in
:ref:`syncserver_alternative_databases`.


Running the Server
==================

Now you can run the server using paster and the provided "development.ini"
file::

    $ bin/paster serve development.ini
    Starting server in PID 29951.
    serving on 0.0.0.0:5000 view at http://127.0.0.1:5000

Once the server is launched, you can run the Firefox Sync Wizard and choose
*http://localhost:5000* as your Firefox Custom Sync Server.

You should then see a lot of output in the stdout, which are the calls made
by the browser for the initial sync.


Updating the server
===================

You should periodically update your code to make sure you've got the latest
fixes.  The following commands will update server-full in place::

    $ cd /path/to/server-full
    $ hg pull
    $ hg update
    $ make build

By default, the **build** command will checkout the latest released tags for
each server product.  If you need access to a fix that has not yet been
released (or if you just want to live on the bleeding edge) then you can 
build the development channel like so::

    $ make build CHANNEL=dev


.. note:: Due to a change in how authentication is handled, users upgrading
   from a build made prior to January 2012 may need to migrate user accounts
   into a new database table.  To do so:

      1. Check that the [auth] section in your config file is using the
        "services.user.sql.SQLUser" backend.

      2. Check if your database contains a "users" table.

      3. If so, use the following migration script to move data
         into the "user" table::

            deps/server-core/migrations/auth.sql_to_user.sql_migration.txt


Security Notes
==============

File Permissions
::::::::::::::::

The default configuration of the server uses a file-based sqlite database,
so you should carefully check that the permissions on this file are appropriate
for your setup.  The file and its containing directory should be writable by
the user under which the server is running, and inaccessible to other users
on the system.

You may like to set the umask of the server process to ensure that any files
it creates are readable only by the appropriate user.  For example::

    $ umask 007
    $ bin/paster serve development.ini


Disabling New Users
:::::::::::::::::::

The default configuration of the server allows new users to create an account
through Firefox's builtin setup screen.  This is useful during initial setup,
but it means that *anybody* could sync against your server if they know its
URL.

You can disable creation of new accounts by setting **auth.allow_new_users**
to **false** in the config file::

       [auth]
       allow_new_users = false



.. _syncserver_alternative_databases:

Using MYSQL or LDAP or ...
==========================

Instead of SQLite, you can use alternative backends:

- Open-LDAP to store the users
- A SQLAlchemy-compatible database, to store the sync data and/or the users

Sync has been tested on MySQL and Postgres.

In order to use a specific Database, you need to install the required
headers, and the required Python library in the local Python environment.

See http://www.sqlalchemy.org/docs/core/engines.html#supported-dbapis

For example, to run everything in MySQL:

1. install *libmysqlclient-dev* and *mysql-server*
2. install *Mysql-Python by* running **bin/easy_install Mysql-Python**
3. change the configuration file located at *etc/sync.conf*


For #3, see :ref:`configuration`.


For SQL databases, the code will create three tables:

  * *user*:  contains the user accounts, mapping email to numeric id.
  * *collections*:  contains collection names for each user, by numeric id.
  * *wbo*:  contains individual sync records for each user, by numeric id.



Running behind a Web Server
===========================

The built-in server should not be used in production, as it does not really
support a lot of load.

If you want to set up a production server, you can use different web servers
that are compatible with the WSGI protocol. For example:

- *Apache* combined with *mod_wsgi*
- *NGinx* with *Gunicorn* or *uWSGI*
- *lighttpd* with *flup*, using the *fcgi* or *scgi* protocol


.. note:: Remember, you must set the **nodes.fallback_node** option to the
   client-visible URL of your sync server.

   For example, if your server will be located at http://example.com/ff-sync/,
   the fallback node should be set to this value in your config file::

       [nodes]
       fallback_node = http://example.com/ff-sync/


Apache + mod_wsgi
:::::::::::::::::

Here's an example of an Apache 2.2 setup that uses mod_wsgi::

  <Directory /path/to/sync>
    Order deny,allow
    Allow from all
  </Directory>

  <VirtualHost \*:80>
    ServerName example.com
    DocumentRoot /path/to/sync
    WSGIProcessGroup sync
    WSGIDaemonProcess sync user=sync group=sync processes=2 threads=25
    WSGIPassAuthorization On
    WSGIScriptAlias / /path/to/sync/sync.wsgi
    CustomLog /var/log/apache2/example.com-access.log combined
    ErrorLog  /var/log/apache2/example.com-error.log
  </VirtualHost>

Here's the equivalent setup for Apache 2.4, which uses a different syntax
for acess control::

  <Directory /path/to/sync>
    Require all granted
  </Directory>

  <VirtualHost \*:80>
    ServerName example.com
    DocumentRoot /path/to/sync
    WSGIProcessGroup sync
    WSGIDaemonProcess sync user=sync group=sync processes=2 threads=25
    WSGIPassAuthorization On
    WSGIScriptAlias / /path/to/sync/sync.wsgi
    CustomLog /var/log/apache2/example.com-access.log combined
    ErrorLog  /var/log/apache2/example.com-error.log
  </VirtualHost>

We provide a **sync.wsgi** file for your convenience in the repository.
Before running Apache, edit the file and check that it loads the the right
.ini file with its full path.

Nginx + Gunicorn
::::::::::::::::

Tested with debian stable/squeeze

1. First install gunicorn in the server-full python version::

        $ cd /usr/src/server-full
        $ bin/easy_install gunicorn

2. Then enable gunicorn in the **developement.ini**::

        [server:main]
        use = egg:gunicorn
        host = 127.0.0.1
        port = 5000
        workers = 2
        timeout = 60

3. Edit **etc/sync.conf**::

        [nodes]
        fallback_node = https://www.yourserver.net/some/path/

4. Finally edit your nginx vhost file::

        server {
                listen  443 ssl;
                server_name sync.example.com;

                ssl_certificate /path/to/your.crt;
                ssl_certificate_key /path/to/your.key;

                location / {
                        proxy_pass_header Server;
                        proxy_set_header Host $http_host;
                        proxy_redirect off;
                        proxy_set_header X-Real-IP $remote_addr;
                        proxy_set_header X-Scheme $scheme;
                        proxy_connect_timeout 10;
                        proxy_read_timeout 120;
                        proxy_pass http://localhost:5000/;
                        }
                }

5. After restarting your nginx and server-full you should be able to use the
   sync server behind your nginx installation


lighttpd + flup + fcgi
::::::::::::::::::::::

Tested under Gentoo.


1. Make sure you have the following packages installed:

    - virtualenv
    - mercurial

    With Gentoo use::

        emerge -avuDN virtualenv mercurial

1. Install flup in the server-full python version::

        $ cd /usr/src/server-full
        $ bin/easy_install flup

4. I had to edit the Makefile to take out the memcache dependency. YMMV.

5. Edit **development.ini**::

    [server:main]
    use = egg:Flup#fcgi_thread
    host = 0.0.0.0
    port = 5000

Be sure to remove the "use_threadpool" and "threadpool_workers" options
from this section, since fcgi does not support them.

6. Edit **etc/sync.conf**::

    [storage]
    backend = syncstorage.storage.sql.SQLStorage
    sqluri = sqlite:////usr/src/server-full/weave_storage
    create_tables = true

    [auth]
    backend = services.user.sql.SQLUser
    sqluri = sqlite:////usr/src/server-full/weave_user
    create_tables = true

    [nodes]
    fallback_node = https://www.yourserver.net/some/path/

7. Edit your **lighttpd.conf**::

        server.modules   += ( "mod_fastcgi" )
        fastcgi.server    = (   "/some/path" => ((
                                "host" => "127.0.0.1",
                                "port" => 5000,
                        "idle-imeout" => 32,
                        "check-local" => "disable",
                        "disable-time" => 1,
                        "fix-root-scriptname" => "enable"
                        ))
                    )

Be sure to **not** add a trailing slash after "/some/path", otherwise you will get a 404 error.

8. Start the Python server::

        /usr/src/server-full/paster serve /usr/src/server-full/development.ini --daemon

9. Restart your lighttpd::

        /etc/init.d/lighttpd restart


Troubleshooting
===============

Most issues with the server are caused by bad configuration. If your server does
not work properly, the first thing to do is to visit **about:sync-log** in
Firefox to see if there's any error.

You will see a lot of logs and if the sync failed probably an error.

Misconfigured storage node
::::::::::::::::::::::::::

If the last successful call is finishing like this::

    2011-02-24 11:17:57 Net.Resource         DEBUG  GET success 200 http://server/user/1.0/.../node/weave

But is not followed by::

    2011-02-24 11:17:57 Service.Main         DEBUG  cluster value = http://server/
    2011-02-24 11:17:57 Service.Main         DEBUG  Caching URLs under storage user base: http://server/.../
    2011-02-24 11:17:57 Net.Resource         DEBUG  GET success 200 http://server/.../info/collections

It probably means that your server **fallback_node** option is not properly
configured. See the previous section.

Getting a lot of 404
::::::::::::::::::::

Check your server logs and make sure your VirtualHost is properly configured.
Looking at the server log might help.


Getting some 500 errors
:::::::::::::::::::::::

Check your server logs and look for some tracebacks. Also, make sure your
server-full code is up-to-date by running **make build**

Some common errors:

- `KeyError: "Unknown fully qualified name for the backend: 'sql'"`

  This error means that your backend configuration is outdated. Use the
  fully qualified names described in the previous sections.

- Various datatype-related errors

  This could indicate that your webserver's own authentication system is
  interacting badly with the sync server's own system.  You may need to
  e.g. disable apache's basic auth system.


Firefox says the server URL is invalid
::::::::::::::::::::::::::::::::::::::

Check that you have entered the full URL, including a leading "http://" or
"https://" component.

Check that you're not running your server on a port number that is commonly
used for other services, such as port 22 (used by ssh) or port 6000 (used by
X11).  Firefox may prevent outgoing HTTP connections to these ports for
security reasons.

The current list of blocked ports can be viewed at http://dxr.mozilla.org/mozilla-central/netwerk/base/src/nsIOService.cpp.html#l70.


Can't get it to work
::::::::::::::::::::

Ask for help:

- on IRC (irc.mozilla.org) in the #sync channel
- in our Mailing List: https://mail.mozilla.org/listinfo/sync-dev
