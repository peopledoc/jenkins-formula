{% set jenkins = pillar.get('jenkins', {}) -%}

remove_cli:
  file.absent:
    - name: /usr/local/sbin/jenkins-cli

remove_jar:
  file.absent:
    - name: /usr/lib/jenkins
