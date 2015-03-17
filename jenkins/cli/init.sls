{% set jenkins = pillar.get('jenkins', {}) -%}
{% set libdir = '/usr/lib/jenkins' -%}
{% if 'jenkins-master' in grains['roles'] -%}
{% set master_ip = salt['network.ip_addrs']()[0] -%}
{% else -%}
{% set ip_addrs = salt['publish.publish']('roles:jenkins-master', 'network.ip_addrs', expr_form='grain') -%}
{% set master_ip = ip_addrs.values()[0][0] -%}
{% endif -%}

curl_pkg:
  pkg.latest:
    - name: curl

{% if 'jenkins-master' in grains['roles'] -%}
force_jenkins_restart:
  cmd.run:
    - name: service jenkins restart
{%- endif %}

wait_master:
  cmd.run:
    - name: curl --silent --show-error --head --retry-delay 2 --retry 20 http://{{ master_ip }}/
    - require:
      - pkg: curl_pkg
{%- if 'jenkins-master' in grains['roles'] %}
      - cmd: force_jenkins_restart
{%- endif %}

libdir:
  file.directory:
    - name: {{ libdir }}

cli_jar:
  cmd.run:
    - name: curl --retry 5 --fail -O http://{{ master_ip }}/jnlpJars/jenkins-cli.jar
    - cwd: {{ libdir }}
    - creates: {{ libdir }}/jenkins-cli.jar
    - require:
      - cmd: wait_master

jenkins_cli:
  file.managed:
    - name: /usr/local/sbin/jenkins-cli
    - source: salt://jenkins/cli/jenkins-cli
    - mode: 0750
    - template: jinja
    - defaults:
        jar: {{ libdir }}/jenkins-cli.jar
        ip: {{ master_ip }}
