{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set group = jenkins.get('group', user) -%}
{% set keys = salt['publish.publish']('roles:jenkins-master', 'ssh_key.pub', user, expr_form='grain') %}
{% set master_key = keys.values()[0] %}
{% set labels = grains.get('jenkins', {}).get('labels', []) -%}
{% set node = grains.get('jenkins', {}).get('name', grains['nodename']) -%}
{% set num_executors = grains.get('jenkins', {}).get('executors', grains['num_cpus']) -%}
{% set host = jenkins.get('master') -%}
{%- if not host %}
{# Calculate subnet: First master, first IP after 127, trim last byte, add CIDR #}
{% set masters_ip = salt['publish.publish']('roles:jenkins-master', 'grains.get', 'ipv4', expr_form='grain') -%}
{% set netmask = masters_ip.values()[0][1].rsplit('.', 1)[0] + '.0/24' -%}
{% set host = salt['network.ip_addrs'](cidr=netmask)[0] -%}
{%- endif %}

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
    - host: {{ host }}
    - remote_fs: {{ home }}
    - num_executors: {{ num_executors }}
    - credential: master-ssh
{%- if labels %}
    - labels:
{%- for label in labels %}
      - {{ label }}
{%- endfor %}
{%- endif %}
