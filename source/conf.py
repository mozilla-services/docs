# -*- coding: utf-8 -*-
import os
from datetime import datetime
import mozilla_sphinx_theme


extensions = [
    'sphinx.ext.graphviz',
    'sphinx.ext.viewcode',
    'sphinxcontrib.seqdiag',
]

try:
    import sphinxcontrib.spelling
except ImportError:
    pass
else:
    extensions.append("sphinxcontrib.spelling")

graphviz_output_format = 'svg'
blockdiag_antialias = True
seqdiag_antialias = True

templates_path = ['_templates']
html_theme_path = [os.path.dirname(mozilla_sphinx_theme.__file__)]
html_theme = 'mozilla'
source_suffix = '.rst'
master_doc = 'index'
project = u'Mozilla Services'
year = datetime.now().year
copyright = u'%s, Mozilla Foundation, CC BY-SA 2.5' % year
version = ''
release = ''
exclude_patterns = []
pygments_style = 'sphinx'

html_title = "Mozilla Services"
html_static_path = []

CURDIR = os.path.dirname(__file__)
sidebars = []
for f in os.listdir(CURDIR):
    name, ext = os.path.splitext(f)
    if ext != '.rst':
        continue
    sidebars.append((name, 'indexsidebar.html'))

html_sidebars = dict(sidebars)
htmlhelp_basename = 'Mozilla Servicesdoc'

latex_documents = [
  ('index', 'Mozilla Services.tex', u'Mozilla Services Documentation',
   u'Tarek Ziade', 'manual'),
]

man_pages = [
    ('index', 'sync', u'Mozilla Services Documentation',
     [u'Tarek Ziade'], 1)
]

