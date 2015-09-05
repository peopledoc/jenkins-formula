include:
  - docker
  - jenkins.user

# no apt-cache for docker repo, @see: https://github.com/docker/docker/issues/9592
docker_no_apt_cache:
  file.append:
    - name: /etc/apt/apt.conf.d/02docker
    - text: Acquire::HTTP::Proxy::apt.dockerproject.org "DIRECT";
    - require_in:
      - pkgrepo: docker package repository

jenkins_group_docker:
  module.run:
    - name: user.chgroups
    - m_name: jenkins
    - groups:
      - docker
    - append: True
