
{% if grains['oscodename'] != 'jessie' -%}
include:
  - supervisor.service
{%- endif %}

curl:
  pkg.latest:

{% if grains['oscodename'] == 'wheezy' -%}
backports_repo:
  pkgrepo.managed:
    - name: deb http://ftp.us.debian.org/debian wheezy-backports main
    - file: /etc/apt/sources.list.d/wheezy-backports.list
{%- endif %}

nodejs_pkg:
  pkg.installed:
    - name: nodejs
{%- if grains['oscodename'] == 'wheezy' %}
    - require:
      - pkgrepo: backports_repo
{%- endif %}

node_link:
  file.symlink:
    - name: /usr/bin/node
    - target: /usr/bin/nodejs
    - require:
      - pkg: curl
      - pkg: nodejs

npm:
  cmd.run:
    - name: curl https://www.npmjs.com/install.sh | sh
    - require:
      - file: node_link

hookforward:
  cmd.run:
    - name: npm install -g hookforward
    - require:
      - cmd: npm

{% if grains['oscodename'] != 'jessie' -%}

{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}

{% set hookforward = pillar.get('hookforward', {}) -%}
{% set cloudant_url = hookforward.get('cloudant_url') %}
{% set username = hookforward.get('username', '') %}
{% set password = hookforward.get('password', '') %}
{% set webhook_url = hookforward.get('webhook_url') %}

{% from "supervisor/map.jinja" import supervisor with context %}
hookforward_supervisor_config:
  file.managed:
    - name: {{ supervisor.include_confdir }}/hookforward.conf
    - template: jinja
    - source: salt://hookforward/supervisor.conf.tmpl
    - require:
      - cmd: hookforward
    - context:
      cloudant_url: {{ cloudant_url }}
      username: {{ username }}
      password: {{ password }}
      webhook_url: {{ webhook_url }}
      user: jenkins
      home: {{ home }}
      logdir: {{ supervisor.logdir }}

extend:
  supervisor-service:
    service:
      - reload: True
      - watch:
        - file: hookforward_supervisor_config
{%- endif %}
