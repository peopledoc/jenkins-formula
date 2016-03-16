{% from 'jenkins/map.jinja' import jenkins -%}

ssh_key:
  cmd.run:
    - name: test -f  {{ jenkins.home }}/.ssh/id_rsa || ssh-keygen -q -N '' -f {{ jenkins.home }}/.ssh/id_rsa
    - user: {{ jenkins.user }}
    - creates: {{ jenkins.home }}/.ssh/id_rsa

ssh_config:
  file.append:
    - name: {{ jenkins.home }}/.ssh/config
    - source: salt://jenkins/master/ssh_config
