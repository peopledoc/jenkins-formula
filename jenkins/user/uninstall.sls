{% set jenkins = pillar.get('jenkins', {}) -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}

remove_user:
  user.absent:
    - name: {{ user }}

remove_home:
  file.absent:
    - name: {{ home }}
