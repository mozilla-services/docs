=================
Coding guidelines
=================

Style
=====

All the code must follow PEP 8. You can use Flake8 to check for compliance.
Flake8 is installed by default to all server environments, via MoPyTools.

Flake8 provides a Mercurial hook, to perform a code check on every commit or
qrefresh. Here's an example of Mercurial ~/.hgrc file::

    [hooks]
    commit = python:flake8.run.hg_hook
    qrefresh = python:flake8.run.hg_hook

    [flake8]
    strict = 0

If strict option is set to 1, any warning will block the commit.
When strict is set to 0, warnings are just displayed in the standard output.

Read these:

- Flake8 documentation: http://pypi.python.org/pypi/flake8
- PEP 8 - The official style guideline: http://www.python.org/dev/peps/pep-0008


Unicode vs Str
==============

All internal strings in our server applications must use the **unicode** type
unless stated otherwise.

Exceptions are:

- Rendered e-mails
- LDAP or SQL specific values

When the **str** type is used, the **utf-8** encoding must be used::

    >>> uni = u'Café'
    >>> uni
    u'Caf\xe9'
    >>> uni.encode('utf-8')
    'Caf\xc3\xa9'
    >>> print uni.encode('utf-8')
    Café
    >>> print uni
    Café

More on Unicode : http://docs.python.org/howto/unicode.html

