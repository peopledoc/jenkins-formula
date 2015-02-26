base:
  'roles:jenkins-master':
    - match: grain
    - jenkins.master

  'roles:jenkins-slave':
    - match: grain
    - jenkins.slave
