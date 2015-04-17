
include:
  - docker
  - jenkins.user

jenkins_group_docker:
  module.run:
    - name: user.chgroups
    - m_name: jenkins
    - groups:
      - docker
    - append: True
