base:
  'roles:jenkins-master':
    - match: grain
    - jenkins
    - jenkins.nginx
    - jenkins.cli

  'roles:jenkins-slave':
    - match: grain
    - jenkins.slave
    - jenkins.cli
