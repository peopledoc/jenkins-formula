{% set jenkins = pillar.get('jenkins', {}) -%}
{% if 'jenkins-master' in grains['roles'] -%}
{% set master_ip = grains['ipv4'][0] -%}
{% else -%}
{% set ip_addrs = salt['publish.publish']('roles:jenkins-master', 'network.ip_addrs', expr_form='grain') -%}
{% set master_ip = ip_addrs.values()[0][0] -%}
{% endif -%}
{% set libdir = '/usr/lib/jenkins' -%}

curl_pkg:
  pkg.latest:
    - name: curl

wait_master:
  cmd.run:
    - name: curl --silent --show-error --head --retry-delay 2 --retry 20 http://{{ master_ip }}/
    - require:
      - pkg: curl_pkg

libdir:
  file.directory:
    - name: {{ libdir }}

cli_jar:
  cmd.run:
    - name: wget http://{{ master_ip }}/jnlpJars/jenkins-cli.jar
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
