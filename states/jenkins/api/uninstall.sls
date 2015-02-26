{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}

delete_jenkinsapi:
  file.absent:
    - name: {{ home }}/.virtualenvs/jenkinsapi
