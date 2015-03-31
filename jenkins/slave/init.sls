{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set group = jenkins.get('group', user) -%}
{% set keys = salt['publish.publish']('roles:jenkins-master', 'ssh_key.pub', user, expr_form='grain') %}
{% set master_key = keys.values()[0] %}
{% set labels = grains.get('jenkins', {}).get('labels', []) -%}
{% set node = grains.get('jenkins', {}).get('name', grains['host']) -%}

include:
  - jenkins.user
  - jenkins.cli
  - jenkins.git

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

slave_node:
  jenkins_node.present:
    - name: {{ node }}
    - host: {{ salt['network.ip_addrs']()[0] }}
    - remote_fs: {{ home }}
    - credential: master-ssh
{%- if labels %}
    - labels:
{%- for label in labels %}
      - {{ label }}
{%- endfor %}
{%- endif %}
