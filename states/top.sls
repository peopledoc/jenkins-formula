base:
  'roles:jenkins-master':
    - match: grain
    - jenkins
    - jenkins.nginx
