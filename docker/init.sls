{% set docker = pillar.get('docker', {}) -%}
{% set docker_opts = docker.get('opts') -%}

docker_pkg:
  pkg.installed:
    - name: docker.io

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
