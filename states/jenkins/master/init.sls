include:
  - jenkins
  - jenkins.nginx
  - jenkins.cli
  - jenkins.api

service_jenkins:
  service.enabled:
    - name: jenkins

extend:
  nginx:
    service:
      - require:
        - file: /etc/nginx/sites-enabled/jenkins.conf
