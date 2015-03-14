{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set group = jenkins.get('group', user) -%}

include:
  - jenkins
  - jenkins.nginx
  - jenkins.cli
  - jenkins.plugins
  - jenkins.git
  - hookforward

{% if grains['oscodename'] == 'jessie' -%}
patch_nginx_conf:
  file.comment:
    - name: /etc/nginx/nginx.conf
    - regex: daemon
    - char: '# '

extend:
  nginx:
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
    - name: test -f  {{ home }}/.ssh/id_rsa || ssh-keygen -q -N '' -f {{ home }}/.ssh/id_rsa
    - user: {{ user }}
    - creates: {{ home }}/.ssh/id_rsa

ssh_config:
  file.append:
    - name: {{ home }}/.ssh/config
    - source: salt://jenkins/master/ssh_config

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

jenkins_nodeMonitors:
  file.managed:
    - name: {{ home }}/nodeMonitors.xml
    - mode: 0644
    - user: {{ user }}
    - group: {{ group }}
    - source: salt://jenkins/master/nodeMonitors.xml

jenkins_safe_restart:
  # safe-restart is required by nodeMonitors
  jenkins.restart:
    - watch:
      - file: jenkins_config
      - file: jenkins_credentials
      - file: jenkins_nodeMonitors
