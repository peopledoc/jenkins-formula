base:
  'roles:jenkins-master':
    - match: grain
    - jenkins

  'roles:jenkins-slave':
    - match: grain
    - jenkins