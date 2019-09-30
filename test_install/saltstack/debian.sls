{# Import global parameters that source from grains and pillars #}
{% import 'params.jinja' as params %}

{% if params.use_latest %}
  {% set repo_url = 'https://{0}repo.saltstack.com/{1}{2}/debian/{3}/{4}/latest' %}
  {% set repo_url = repo_url.format(params.repo_auth, params.dev, params.py_dir, params.os_major_release, params.os_arch) %}
{% elif params.test_rc_pkgs %}
  {% set repo_url = 'https://repo.saltstack.com/{0}salt_rc/{1}/debian/{2}/{3}/' %}
  {% set repo_url = repo_url.format(params.dev, params.py_dir, params.os_major_release, params.os_arch) %}
{% else %}
  {% set repo_url = 'https://{0}repo.saltstack.com/{1}{2}/debian/{3}/{4}/archive/{5}' %}
  {% set repo_url = repo_url.format(params.repo_auth, params.dev, params.py_dir, params.os_major_release, params.os_arch, params.salt_version) %}
{% endif %}

{% set key_url = '{0}/SALTSTACK-GPG-KEY.pub'.format(repo_url) %}

{% if params.on_deb_7 %}
{% set key_url = 'http://' + key_url.split('https://')[1] %}
{% endif %}

{% set cherrypy = 'python-cherrypy3' %}
{% if params.python3 %}
    {% set cherrypy = 'python3-cherrypy3' %}
{% endif %}

install-python-apt:
  pkg.installed:
    - name: python-apt

pre_update-package-database:
  module.run:
    - name: pkg.refresh_db

install-https-transport:
  pkg.installed:
    - name: apt-transport-https

add-repo:
  pkgrepo.managed:
    - name: deb {{ repo_url }} {{ params.os_code_name }} main
    - file: /etc/apt/sources.list.d/salt-{{ params.repo_version }}.list
    - key_url: {{ key_url }}
    - require:
      - pkg: install-https-transport

update-package-database:
  module.run:
    - name: pkg.refresh_db
    - require:
      - pkgrepo: add-repo

{% if params.upgrade %}
upgrade-salt:
  cmd.run:
    - name: apt-get install --no-install-recommends -y -o Dpkg::Options::="--force-confdef" --only-upgrade {{ params.pkgs | join(' ') }}

{% else %}

install-salt:
  cmd.run:
    - name: apt-get --no-install-recommends -y install {{ params.versioned_pkgs | join(' ') }}
    - require:
      - module: update-package-database

install-cherrypy:
  cmd.run:
    - name: apt-get -y install {{ cherrypy }}

{% endif %}
