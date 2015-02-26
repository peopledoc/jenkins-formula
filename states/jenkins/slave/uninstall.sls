{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}

delete_user:
  user.absent:
    - name: jenkins

delete_home:
  file.absent:
    - name: {{ home }}
