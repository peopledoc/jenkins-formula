{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set keys = salt['publish.publish']('roles:jenkins-master', 'ssh_key.pub', user, expr_form='grain') %}
{% set master_key = keys.values()[0] %}
{% set ssh_credential = jenkins.get('ssh_credential', '0c952d99-54de-44c4-99d8-86f2c3acf170') %}

include:
  - jenkins.cli

jre:
  pkg.latest:
    - name: openjdk-6-jre-headless

ssh:
  pkg.latest:
    - name: openssh-server

jenkins_user_slave:
  user.present:
    - name: jenkins
    - home: {{ home }}

allow_master_key:
  ssh_auth.present:
    - name: {{ master_key }}
    - user: {{ user }}

node:
  jenkins_node.present:
    - name: {{ grains['host'] }}
    - remote_fs: {{ home }}
    - credential: {{ ssh_credential }}
