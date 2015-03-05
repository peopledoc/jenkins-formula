
{% if grains['oscodename'] != 'jessie' -%}
include:
  - supervisor.service
{%- endif %}

curl:
  pkg.latest:

{% if grains['oscodename'] != 'jessie' -%}
backports_repo:
  pkgrepo.managed:
    - name: deb http://ftp.us.debian.org/debian wheezy-backports main
    - file: /etc/apt/sources.list.d/wheezy-backports.list
{%- endif %}

nodejs_pkg:
  pkg.installed:
    - name: nodejs
{%- if grains['oscodename'] != 'jessie' %}
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
