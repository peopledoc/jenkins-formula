{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}

remove_cli:
  file.absent:
    - name: /usr/local/bin/jenkins-cli

remove_cli_jar:
  file.absent:
    - name: {{ home }}/jenkins-cli.jar
