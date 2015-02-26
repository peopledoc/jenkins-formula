{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}

jre:
  pkg.latest:
    - name: openjdk-6-jre-headless

jenkins_user:
  user.present:
    - name: jenkins
    - home: {{ home }}

ssh_key:
  cmd.run:
    - name: ssh-keygen -q -N '' -f {{ home }}/.ssh/id_rsa
    - user: jenkins
    - creates: {{ home }}/.ssh/id_rsa
