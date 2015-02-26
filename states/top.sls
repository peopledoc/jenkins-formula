base:
  'roles:jenkins-master':
    - match: grain
    - jenkins
    - jenkins.nginx
    - jenkins.api
    - jenkins.cli

  'roles:jenkins-slave':
    - match: grain
    - jenkins.slave
    - jenkins.api
    - jenkins.cli
