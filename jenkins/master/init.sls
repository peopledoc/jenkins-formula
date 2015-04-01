{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set group = jenkins.get('group', user) -%}

include:
  - jenkins.systemd
  - jenkins
  - jenkins.nginx
  - jenkins.cli
  - jenkins.plugins
  - jenkins.views
  - jenkins.master.config
  - jenkins.git
  - hookforward

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
      - jenkins_config: jenkins_config_executors
{%- if slave_agent_port %}
      - jenkins_config: jenkins_config_slave_port
{%- endif %}
      - file: jenkins_credentials
      - file: jenkins_nodeMonitors
