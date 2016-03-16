{% from 'jenkins/map.jinja' import jenkins -%}
{% set github_user = salt['pillar.get']('jenkins:github:username') -%}
{% set github_token = salt['pillar.get']('jenkins:github:token') -%}

{% for name, value in jenkins.config|dictsort %}
jenkins_config_{{ name }}:
  jenkins_config.managed:
    - name: {{ name }}
    - text: {{ value }}
{% endfor %}

jenkins_location:
  file.managed:
    - name: {{ jenkins.home }}/jenkins.model.JenkinsLocationConfiguration.xml
    - mode: 0644
    - user: {{ jenkins.user }}
    - group: {{ jenkins.group }}
    - template: jinja
    - source: salt://jenkins/master/location.xml

jenkins_nodeMonitors:
  file.managed:
    - name: {{ jenkins.home }}/nodeMonitors.xml
    - mode: 0644
    - user: {{ jenkins.user }}
    - group: {{ jenkins.group }}
    - source: salt://jenkins/master/nodeMonitors.xml

jenkins_Shell:
  file.managed:
    - name: {{ jenkins.home }}/hudson.tasks.Shell.xml
    - mode: 0644
    - user: {{ jenkins.user }}
    - group: {{ jenkins.group }}
    - template: jinja
    - source: salt://jenkins/master/hudson.tasks.Shell.xml
    - context:
      shell: {{ jenkins.shell }}

jenkins_config_modified:
  cmd.wait:
    - name: "true"
    - watch:
        - file: jenkins_nodeMonitors
        - file: jenkins_Shell
        - file: jenkins_location

{% if github_user -%}
jenkins_github_settings:
  file.managed:
    - name: {{ jenkins.home }}/com.cloudbees.jenkins.GitHubPushTrigger.xml
    - source: salt://jenkins/master/github.xml
    - template: jinja
    - defaults:
        user: {{ github_user }}
        token: {{ github_token }}
    - watched_in:
        - cmd: jenkins_config_modified
{%- endif %}
