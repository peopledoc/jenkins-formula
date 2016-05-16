{% from 'jenkins/map.jinja' import jenkins -%}

{%- for name, value in jenkins.config|dictsort %}
jenkins_config_{{ name }}:
  jenkins_config.managed:
    - name: {{ name }}
    - text: {{ value }}
{%- endfor %}

jenkins_location:
  file.managed:
    - name: {{ jenkins.home }}/jenkins.model.JenkinsLocationConfiguration.xml
    - mode: 0644
    - user: {{ jenkins.user }}
    - group: {{ jenkins.group }}
    - template: jinja
    - source: salt://jenkins/master/location.xml
    - context:
        jenkins: {{ jenkins|json }}

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

{% if jenkins.github.username -%}
jenkins_github_settings:
  file.managed:
    - name: {{ jenkins.home }}/com.cloudbees.jenkins.GitHubPushTrigger.xml
    - source: salt://jenkins/master/github.xml
    - user: {{ jenkins.user }}
    - group: {{ jenkins.group }}
    - template: jinja
    - defaults:
        user: {{ jenkins.github.username }}
        token: {{ jenkins.github.token }}
    - watched_in:
        - cmd: jenkins_config_modified
{%- endif %}
