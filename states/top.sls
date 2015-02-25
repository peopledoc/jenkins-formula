base:
  'roles:jenkins-master':
    - match: grain
    - jenkins
    - jenkins.nginx

  'roles:jenkins-slave':
    - match: grain
    - jenkins.slave
