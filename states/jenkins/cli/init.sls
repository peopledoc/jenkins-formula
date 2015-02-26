{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set ip_addrs = salt['publish.publish']('roles:jenkins-master', 'network.ip_addrs', expr_form='grain') %}
{% set master_ip = ip_addrs.values()[0][0] %}

cli_jar:
  cmd.run:
    - name: wget http://{{ master_ip }}/jnlpJars/jenkins-cli.jar
    - user: jenkins
    - cwd: {{ home }}
    - creates: {{ home }}/jenkins-cli.jar


cli_script:
  file.managed:
    - name: /usr/local/bin/jenkins-cli
    - source: salt://jenkins/files/jenkins-cli
    - mode: 0750
    - user: root
    - group: jenkins
    - template: jinja
    - defaults:
        jar: {{ home }}/jenkins-cli.jar
        ip: {{ master_ip }}
