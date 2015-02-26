include:
  - jenkins
  - jenkins.nginx
  - jenkins.cli
  - jenkins.api

extend:
  nginx:
    service:
      - require:
        - file: /etc/nginx/sites-enabled/jenkins.conf
