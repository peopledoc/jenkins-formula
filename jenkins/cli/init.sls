{% set jenkins = pillar.get('jenkins', {}) -%}
{% set libdir = '/usr/lib/jenkins' -%}
{% set is_master = 'jenkins-master' in grains.roles -%}
{% set master = salt['pillar.get']('jenkins:server_name') -%}
{% if not master -%}
{% if is_master -%}
{% set master = grains['fqdn'] -%}
{% else -%}
{% set master = salt['mine.get']('roles:jenkins-master', 'fqdn', expr_form='grain').values()[0] -%}
{% endif -%}
{% endif -%}

curl_pkg:
  pkg.latest:
    - name: curl

{% if is_master -%}
force_jenkins_restart:
  cmd.run:
    - name: service jenkins restart
{%- endif %}

libdir:
  file.directory:
    - name: {{ libdir }}

cli_jar:
  cmd.run:
    - name: curl --silent --show-error --retry 300 --retry-delay 1 --fail -O http://{{ master }}/jnlpJars/jenkins-cli.jar
    - cwd: {{ libdir }}
    - creates: {{ libdir }}/jenkins-cli.jar
    - require:
      - pkg: curl_pkg
      - file: libdir
{%- if is_master %}
      - cmd: force_jenkins_restart
{%- endif %}

jenkins_cli:
  file.managed:
    - name: /usr/local/sbin/jenkins-cli
    - source: salt://jenkins/cli/jenkins-cli
    - mode: 0750
    - template: jinja
    - defaults:
        jar: {{ libdir }}/jenkins-cli.jar
        host: {{ master }}
