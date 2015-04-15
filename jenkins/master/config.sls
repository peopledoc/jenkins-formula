{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set num_executors = salt['pillar.get']('jenkins:num_executors', 0) -%}
{% set slave_agent_port = salt['pillar.get']('jenkins:ports:slave_agent') -%}
{% set github_user = salt['pillar.get']('jenkins:github:username') -%}
{% set github_token = salt['pillar.get']('jenkins:github:token') -%}

jenkins_config_executors:
  jenkins_config.managed:
    - name: numExecutors
    - text: {{ num_executors }}

{% if slave_agent_port -%}
jenkins_config_slave_port:
  jenkins_config.managed:
    - name: slaveAgentPort
    - text: {{ slave_agent_port }}
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
{%- endif %}
