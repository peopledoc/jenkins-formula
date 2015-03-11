
include:
  - docker
  - jenkins.user

extend:
  jenkins_user:
    user.present:
      - uid: 1000
      - gid: 1000

docker_group:
  group.present:
    - name: docker
    - addusers:
      - jenkins
