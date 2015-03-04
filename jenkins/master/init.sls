{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set group = jenkins.get('group', user) -%}
{% set ssh_credential = jenkins.get('ssh_credential', '0c952d99-54de-44c4-99d8-86f2c3acf170') %}

include:
  - jenkins
  - jenkins.nginx
  - jenkins.cli
  - jenkins.plugins
  - hookforward

{% if grains['oscodename'] == 'jessie' -%}
patch_nginx_conf:
  file.comment:
    - name: /etc/nginx/nginx.conf
    - regex: daemon
    - char: '# '
{%- endif %}

service_jenkins:
  service.enabled:
    - name: jenkins

extend:
  jenkins_user:
    user.present:
      - home: {{ home }}
  nginx:
    service:
      - require:
        - file: /etc/nginx/sites-enabled/jenkins.conf
{%- if grains['oscodename'] == 'jessie' %}
    pkg:
      - require:
        - file: patch_nginx_conf
{%- endif %}

jenkins_config:
  file.managed:
    - name: {{ home }}/config.xml
    - mode: 0644
    - user: {{ user }}
    - group: {{ group }}
    - template: jinja
    - source: salt://jenkins/master/config.xml

ssh_key:
  cmd.run:
    - name: ssh-keygen -q -N '' -f {{ home }}/.ssh/id_rsa
    - user: {{ user }}
    - creates: {{ home }}/.ssh/id_rsa

jenkins_credentials:
  file.managed:
    - name: {{ home }}/credentials.xml
    - mode: 0644
    - user: {{ user }}
    - group: {{ group }}
    - template: jinja
    - source: salt://jenkins/master/credentials.xml
    - defaults:
        user: {{ user }}
        credential: {{ ssh_credential }}

jenkins_nodeMonitors:
  file.managed:
    - name: {{ home }}/nodeMonitors.xml
    - mode: 0644
    - user: {{ user }}
    - group: {{ group }}
    - source: salt://jenkins/master/nodeMonitors.xml

reload:
  # safe-restart is required by nodeMonitors
  jenkins.restart:
    - watch:
      - file: jenkins_config
      - file: jenkins_credentials
      - file: jenkins_nodeMonitors
