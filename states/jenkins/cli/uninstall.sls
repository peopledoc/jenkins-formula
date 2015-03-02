{% set jenkins = pillar.get('jenkins', {}) -%}
{% set libdir = '/usr/lib/jenkins' -%}

remove_cli:
  file.absent:
    - name: /usr/local/bin/jenkins-cli

remove_cli_jar:
  file.absent:
    - name: {{ libdir }}/jenkins-cli.jar
