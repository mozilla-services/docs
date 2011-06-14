========================
Run your own Sync Server
========================

The Firefox Sync Server is deployed on our systems using RPM packaging,
and we don't provide any other packaging or publish official RPMs yet.

The easiest way to install a Sync Server is to checkout our repository
and run a build in-place. Once this is done, Sync can be run behind
and Web Server that supports the :term:`WSGI` protocol.


Prerequisites
=============

The various parts are using **Python 2.6** and **Virtualenv**. Make sure your
system have them. Or install them:

- Python 2.6 downloads: http://python.org/download/releases/2.6.6
- Virtualenv: http://pypi.python.org/pypi/virtualenv

To run the server, you will also need to have these packages installed:

- python-dev
- make
- mercurial
- sqlite3 

For example, under a fresh Unbuntu, you can run this command to meet all 
requirements::

    $ sudo apt-get install python-dev mercurial sqlite3 python-virtualenv


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

Running options are kept in an ini-like file that is passed to the
command::

  $ bin/paster serve development.ini 
  Starting server in PID 29951. 
  serving on 0.0.0.0:5000 view at http://127.0.0.1:5000

By default the server is configured to use a SQLite database for the storage
and the user APIs. Once the server is launched, you can point run the 
Firefox Sync Wizard and choose *http://localhost:5000* as your Firefox Custom
Sync Server.

You should then see a lot of output in the stdout, which are the calls made
by the browser for the initial sync. 


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


Running behing a Web Server
===========================

The built-in server should not be used in production, as it does not really
support a lot of load. 

If you want to set up a production server, you can use different web servers 
that are compatible with the WSGI protocol. For example:

- *Apache* combined with *mod_wsgi*
- *NGinx* with *Gunicorn* or *uWSGI*
- *lighttpd* with *flup*, using the *fcgi* or *scgi* protocol


Apache + mod_wsgi
:::::::::::::::::

Here's an example of an Apache setup that uses mod_wsgi::

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


We provide a **sync.wsgi** file for you convenience in the repository.
Before runnong Apache, edit the file and check that it loads the the right 
.ini file with its full path.


lighttpd + flup + fcgi
::::::::::::::::::::::

Tested under Gentoo.


1. Make sure you have the following packages installed: 

    - flup
    - virtualenv
    - mercurial

    With gentoo use::

        emerge -avuDN flup virtualenv mercurial

2. Unpack the server-full python version. Let's say under /usr/src/sync-full

3. Run::

    $ cd usr/src/sync-full/
    $ make build 
    $ bin/easy_install flup

4. I had to edit the Makefile to take out the memcache dependency. YMMV.

5. Edit **development.ini**::

    [server:main]
    use = egg:Flup#fcgi_thread
    host = 0.0.0.0
    port = 5000

6. Edit **conf/sync.ini**::

    [storage]
    backend = sql
    sqluri = sqlite:////usr/src/sync-full/weave_storage
    standard_collections = false

    [auth]
    backend = sql
    sqluri = sqlite:////usr/src/sync-full/weave_user
    pool_size = 100
    pool_recycle = 3600
    create_tables = true
    fallback_node = https://www.yourserver.net/yourpath/

7. Edit your **lighttpd.conf**::

        server.modules   += ( "mod_fastcgi" )
        fastcgi.server    = (   "/yourpath" => ((
                                "host" => "127.0.0.1",
                                "port" => 5000,
                        "idle-imeout" => 32,
                        "check-local" => "disable",
                        "disable-time" => 1,
                        "fix-root-scriptname" => "enable"
                        ))
                    )

8. Start the Python server::

        /usr/src/sync-full/paster serve /usr/src/sync-full/development.ini --daemon

9. Restart your lighttpd::

        /etc/init.d/lighttpd restart
