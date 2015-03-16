
curl:
  pkg.latest

nodejs_pkg:
  pkg.installed:
    - name: nodejs

node_link:
  file.symlink:
    - name: /usr/bin/node
    - target: /usr/bin/nodejs
    - require:
      - pkg: curl
      - pkg: nodejs

npm:
  pkg.installed

{% set hookforward = pillar.get('hookforward', {}) -%}
{% set cloudant_url = hookforward.get('cloudant_url') %}
{% set username = hookforward.get('username', '') %}
{% set password = hookforward.get('password', '') %}
{% set webhook_url = hookforward.get('webhook_url') %}

hookforward:
  npm.installed:
    - require:
      - pkg: npm
  file.managed:
    - name: /etc/systemd/system/hookforward.service
    - template: jinja
    - source: salt://hookforward/hookforward.service.tmpl
    - require:
      - npm: hookforward
    - context:
      cloudant_url: {{ cloudant_url }}
      username: {{ username }}
      password: {{ password }}
      webhook_url: {{ webhook_url }}
  cmd.run:
    - name: systemctl daemon-reload
  service.running:
    - name: hookforward
    - enable: True
    - restart: True
