{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}

include:
  - jenkins.user.uninstall
  - jenkins.cli.uninstall

remove_node:
  jenkins_node.absent:
    - name: {{ grains['host'] }}
    # Execute CLI before CLI is uninstalled
    - order: 1

remove_pkgs:
  pkg.purged:
    - pkgs:
      - default-jre-headless
