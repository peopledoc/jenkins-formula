{% from 'jenkins/map.jinja' import jenkins -%}
{% set configxml = jenkins.home ~ '/config.xml' -%}
{% set bootstrap_jenkins = not salt['file.access'](configxml, 'w') -%}
{% if not bootstrap_jenkins -%}
{% set needle = 'FullControlOnceLoggedInAuthorizationStrategy' -%}
{% set bootstrap_jenkins = salt['file.search'](configxml, needle) -%}
{% endif %}

include:
  - jenkins.systemd
  - jenkins
  - nginx
  - jenkins.nginx

{% if bootstrap_jenkins -%}
jenkins_config:
  file.managed:
    - name: {{ jenkins.home }}/config.xml
    - user: {{ jenkins.user }}
    - group: {{ jenkins.group }}
    - mode: 0640
    - source: salt://jenkins/files/config.xml
    - create: False
{%- endif %}

jenkins_last_exec_version:
  file.managed:
    - name: {{ jenkins.home }}/jenkins.install.InstallUtil.lastExecVersion
    - user: {{ jenkins.user }}
    - group: {{ jenkins.group }}
    - mode: 0640
    - contents: "2.0"
    - contents_newline: False

jenkins_wizard_state:
  file.managed:
    - name: {{ jenkins.home }}/jenkins.install.UpgradeWizard.state
    - user: {{ jenkins.user }}
    - group: {{ jenkins.group }}
    - mode: 0640
    - contents: "2.0"
    - contents_newline: False

{%- if bootstrap_jenkins %}
jenkins_restart:
  service.running:
    - name: jenkins
    - enable: true
    - restart: true
    - watch:
        - file: jenkins_config
{%- endif %}

jenkins_running:
  service.running:
    - name: jenkins
