{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}

include:
  - jenkins
  - jenkins.nginx
  - jenkins.cli
  - jenkins.api

service_jenkins:
  service.enabled:
    - name: jenkins

extend:
  jenkins_user:
    user.present:
      - home: {{ home }}
  nginx:
    service:
      - require:
        - file: /etc/nginx/sites-enabled/jenkins.conf
