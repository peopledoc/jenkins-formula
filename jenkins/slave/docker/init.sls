
include:
  - docker
  - jenkins.user

docker_group:
  group.present:
    - name: docker
    - addusers:
      - jenkins
