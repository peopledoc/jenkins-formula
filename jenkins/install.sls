include:
  - jenkins.systemd
  - jenkins
  - nginx
  - jenkins.nginx

running:
  service.running:
    - name: jenkins
    - enable: True
