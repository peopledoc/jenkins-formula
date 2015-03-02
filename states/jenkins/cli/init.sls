{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set ip_addrs = salt['publish.publish']('roles:jenkins-master', 'network.ip_addrs', expr_form='grain') %}
{% set master_ip = ip_addrs.values()[0][0] %}
{% set jenkins_user = 'jenkins_user_slave' if 'jenkins-slave' in salt['grains.get']('roles') else 'jenkins_user' -%}

curl_pkg:
  pkg.latest:
    - name: curl

wait_master:
  cmd.run:
    - name: curl --silent --show-error --head --retry 20 http://{{ master_ip }}/

cli_jar:
  cmd.run:
    - name: wget http://{{ master_ip }}/jnlpJars/jenkins-cli.jar
    - cwd: {{ home }}
    - creates: {{ home }}/jenkins-cli.jar
    - require:
      - cmd: wait_master

jenkins_cli:
  file.managed:
    - name: /usr/local/sbin/jenkins-cli
    - source: salt://jenkins/files/jenkins-cli
    - mode: 0750
    - template: jinja
    - defaults:
        jar: {{ home }}/jenkins-cli.jar
        ip: {{ master_ip }}
