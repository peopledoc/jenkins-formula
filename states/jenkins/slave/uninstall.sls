{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}

include:
  - jenkins.cli.uninstall

delete_user:
  user.absent:
    - name: jenkins

delete_home:
  file.absent:
    - name: {{ home }}

remove_pkgs:
  pkg.purged:
    - pkgs:
      - openjdk-6-jre-headless
