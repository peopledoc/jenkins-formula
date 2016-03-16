{% from 'jenkins/map.jinja' import jenkins -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set group = jenkins.get('group', user) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set num_executors = salt['pillar.get']('jenkins:num_executors', 0) -%}
{% set slave_agent_port = salt['pillar.get']('jenkins:ports:slave_agent') -%}
{% set shell = jenkins.get('shell', '/bin/bash') -%}
{% set github_user = salt['pillar.get']('jenkins:github:username') -%}
{% set github_token = salt['pillar.get']('jenkins:github:token') -%}

jenkins_config_executors:
  jenkins_config.managed:
    - name: numExecutors
    - text: {{ num_executors }}

{% for name, value in jenkins.config|dictsort %}
jenkins_config_{{ name }}:
  jenkins_config.managed:
    - name: {{ name }}
    - text: {{ value }}
{% endfor %}

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

jenkins_config_modified:
  cmd.wait:
    - name: "true"
    - watch:
        - jenkins_config: jenkins_config_executors
        - file: jenkins_nodeMonitors
        - file: jenkins_Shell

{% if slave_agent_port -%}
jenkins_config_slave_port:
  jenkins_config.managed:
    - name: slaveAgentPort
    - text: {{ slave_agent_port }}
    - watched_in:
        - cmd: jenkins_config_modified
{%- endif %}

{% if github_user -%}
jenkins_github_settings:
  file.managed:
    - name: {{ home }}/com.cloudbees.jenkins.GitHubPushTrigger.xml
    - source: salt://jenkins/master/github.xml
    - template: jinja
    - defaults:
        user: {{ github_user }}
        token: {{ github_token }}
    - watched_in:
        - cmd: jenkins_config_modified
{%- endif %}
