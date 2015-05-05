{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set group = jenkins.get('group', user) -%}
{% set keys = salt['mine.get']('roles:jenkins-master', 'jenkins_ssh_pubkey', expr_form='grain') %}
{% set master_key = keys.values()[0] %}
{% set labels = grains.get('jenkins', {}).get('labels', []) -%}
{% set node = grains.get('jenkins', {}).get('name', grains['nodename']) -%}
{% set num_executors = grains.get('jenkins', {}).get('executors', grains['num_cpus']) -%}

{% set master = jenkins.get('master') -%}
{% if not master -%}
{# Calculate subnet: First master, first IP, trim last bytes, add CIDR #}
{% set masters_ip = salt['mine.get']('roles:jenkins-master', 'ipv4', expr_form='grain') -%}
{% set master = masters_ip.values()[0][0] %}
{% endif -%}
{% set netmask = master.rsplit('.', 2)[0] + '.0.0/16' -%}
{% set host = salt['network.ip_addrs'](cidr=netmask)[0] -%}

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
