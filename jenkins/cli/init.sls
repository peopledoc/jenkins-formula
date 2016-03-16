{% from 'jenkins/map.jinja' import jenkins -%}

curl_pkg:
  pkg.latest:
    - name: curl

{% if jenkins.master.me -%}
force_jenkins_restart:
  cmd.run:
    - name: service jenkins restart
{%- endif %}

libdir:
  file.directory:
    - name: {{ jenkins.libdir }}

cli_jar:
  cmd.run:
    - name: curl --silent --show-error --retry 300 --retry-delay 1 --fail -O {{ jenkins.url }}/jnlpJars/jenkins-cli.jar
    - cwd: {{ jenkins.libdir }}
    - creates: {{ jenkins.libdir }}/jenkins-cli.jar
    - require:
      - pkg: curl_pkg
      - file: libdir
{%- if jenkins.master.me %}
      - cmd: force_jenkins_restart
{%- endif %}

jenkins_cli:
  file.managed:
    - name: /usr/local/sbin/jenkins-cli
    - source: salt://jenkins/cli/jenkins-cli
    - mode: 0750
    - template: jinja
    - defaults:
        jar: {{ jenkins.libdir }}/jenkins-cli.jar
        host: {{ jenkins.master.fqdn }}
