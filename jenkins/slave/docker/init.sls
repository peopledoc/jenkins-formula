
include:
  - docker
  - jenkins.user

extend:
  jenkins_user:
    user:
      - groups:
        - docker
      - require:
        - pkg: docker_pkg
