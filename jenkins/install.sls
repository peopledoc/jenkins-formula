include:
  - jenkins.systemd
  - jenkins
  - jenkins.nginx

running:
  service.running:
    - name: jenkins
    - enable: True
