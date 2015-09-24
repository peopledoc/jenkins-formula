{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set group = jenkins.get('group', user) -%}
{% set slave_agent_port = salt['pillar.get']('jenkins:ports:slave_agent') -%}
{% set shell = jenkins.get('shell', '/bin/bash') -%}

include:
  - jenkins.install
  - jenkins.cli
  - jenkins.plugins
  - jenkins.views
  - jenkins.master.config
  - jenkins.master.ssh
  - jenkins.master.credentials
  - jenkins.git

jenkins_nodeMonitors:
  file.managed:
    - name: {{ home }}/nodeMonitors.xml
    - mode: 0644
    - user: {{ user }}
    - group: {{ group }}
    - source: salt://jenkins/master/nodeMonitors.xml

jenkins_Shell:
  file.managed:
    - name: {{ home }}/hudson.tasks.Shell.xml
    - mode: 0644
    - user: {{ user }}
    - group: {{ group }}
    - template: jinja
    - source: salt://jenkins/master/hudson.tasks.Shell.xml
    - context:
      shell: {{ shell }}

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
      - cmd: jenkins_credentials_modified
