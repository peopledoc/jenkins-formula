
include:
  - docker
  - jenkins.slave

extend:
  jenkins_user_slave:
    user.present:
      - uid: 1000
      - gid: 1000

docker_group:
  group.present:
    - name: docker
    - addusers:
      - jenkins
