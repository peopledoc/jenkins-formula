{% set jenkins = pillar.get('jenkins', {}) -%}
{% set libdir = '/usr/lib/jenkins' -%}
{% if 'jenkins-master' in grains['roles'] -%}
{% set is_master = True -%}
{% set master_ip = grains['fqdn'] -%}
{% else -%}
{% set is_master = False -%}
{% set master_ip = salt['publish.publish']('roles:jenkins-master', 'grains.get', 'fqdn', expr_form='grain').values()[0] -%}
{% endif -%}
{% if 'server_name' in jenkins %}
{% set jenkins_hostname = jenkins.server_name %}
{% else %}
{% set jenkins_hostname = master_ip %}
{% endif %}

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
    - name: curl --silent --show-error --retry 20 --fail -O http://{{ jenkins_hostname }}/jnlpJars/jenkins-cli.jar
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
        ip: {{ jenkins_hostname }}
