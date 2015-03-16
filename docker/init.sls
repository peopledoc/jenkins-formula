{% set docker = pillar.get('docker', {}) -%}
{% set docker_opts = docker.get('opts') -%}

{% if grains['oscodename'] == 'wheezy' -%}
docker_repo:
  pkgrepo.managed:
    - name: deb http://get.docker.com/ubuntu docker main
    - file: /etc/apt/sources.list.d/docker.list
    - keyid: 36A1D7869245C8950F966E92D8576A8BA88D21E9
    - keyserver: keyserver.ubuntu.com
{%- endif %}

docker_pkg:
  pkg.installed:
{%- if grains['oscodename'] == 'wheezy' %}
    - name: lxc-docker
    - refresh: True
    - repo: docker
    - require:
      - pkgrepo: docker_repo
{%- else %}
    - name: docker.io
{%- endif %}

{% if docker_opts -%}
docker_opts:
  file.replace:
    - name: /etc/default/docker
    - pattern: |
        ^.?DOCKER_OPTS=.*
    - repl:
        DOCKER_OPTS="{{ docker_opts }}"\n
    - require:
      - pkg: docker_pkg

docker_restart:
  cmd.run:
    - name: service docker restart
    - watch:
      - file: docker_opts
{%- endif %}
