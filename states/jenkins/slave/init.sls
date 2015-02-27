{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set keys = salt['publish.publish']('roles:jenkins-master', 'ssh_key.pub', user, expr_form='grain') %}
{% set master_key = keys.values()[0] %}

include:
  - jenkins.cli

jre:
  pkg.latest:
    - name: openjdk-6-jre-headless

jenkins_user:
  user.present:
    - name: jenkins
    - home: {{ home }}

allow_master_key:
  ssh_auth.present:
    - name: {{ master_key }}
    - user: {{ user }}
