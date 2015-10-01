{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set user = jenkins.get('user', 'jenkins') -%}

ssh_key:
  cmd.run:
    - name: test -f  {{ home }}/.ssh/id_rsa || ssh-keygen -q -N '' -f {{ home }}/.ssh/id_rsa
    - user: {{ user }}
    - creates: {{ home }}/.ssh/id_rsa

ssh_config:
  file.append:
    - name: {{ home }}/.ssh/config
    - source: salt://jenkins/master/ssh_config
