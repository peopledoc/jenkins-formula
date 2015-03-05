
include:
  - jenkins.slave

{% if grains['oscodename'] != 'jessie' -%}
docker_repo:
  pkgrepo.managed:
    - name: deb https://get.docker.com/ubuntu docker main
    - file: /etc/apt/sources.list.d/docker.list
    - keyid: 36A1D7869245C8950F966E92D8576A8BA88D21E9
    - keyserver: keyserver.ubuntu.com
{%- endif %}

docker_pkg:
  pkg.installed:
{% if grains['oscodename'] == 'jessie' -%}
    - name: docker.io
{% else %}
    - name: lxc-docker
    - repo: docker
    - require:
      - pkgrepo: docker_repo
{%- endif %}

extend:
  jenkins_user_slave:
    user.present:
      - uid: 1000
      - gid: 1000

docker_group:
  group.present:
    - addusers:
      - jenkins
