{% set jenkins = pillar.get('jenkins', {}) -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}

jenkins_user:
  user.present:
    - name: {{ user }}
    - home: {{ home }}
