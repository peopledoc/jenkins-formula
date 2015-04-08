
include:
  - docker
  - jenkins.user

extend:
  jenkins_user:
    user:
      - groups:
        - docker
      - require:
        - service: docker-service
