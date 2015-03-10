{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set group = jenkins.get('group', user) -%}
{% set keys = salt['publish.publish']('roles:jenkins-master', 'ssh_key.pub', user, expr_form='grain') %}
{% set master_key = keys.values()[0] %}
{% set git = jenkins.get('git', {}) -%}
{% set git_hosts = git.get('hosts', []) -%}

include:
  - jenkins.user
  - jenkins.cli

jre:
  pkg.latest:
    - name: default-jre-headless

ssh:
  pkg.latest:
    - name: openssh-server

allow_master_key:
  ssh_auth.present:
    - name: {{ master_key }}
    - user: {{ user }}

node:
  jenkins_node.present:
    - name: {{ grains['host'] }}
    - host: {{ grains['fqdn'] }}
    - remote_fs: {{ home }}
    - credential: master-ssh

git_key:
  file.managed:
    - name: {{ home }}/.ssh/id_rsa_git
    - contents_pillar: jenkins:git:prvkey
    - mode: 0600
    - user: {{ user }}
    - group: {{ group }}

{% for host in git_hosts -%}
git_host_{{ host }}_known:
  ssh_known_hosts.present:
    - name: {{ host }}
    - user: {{ user }}

git_host_{{ host }}_setup:
  file.append:
    - name: {{ home }}/.ssh/config
    - text: |
        Host {{ host }}
             Identityfile ~/.ssh/id_rsa_git
{%- endfor %}
