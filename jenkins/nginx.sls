{% from "jenkins/map.jinja" import jenkins with context %}

jenkins_nginx_logs:
  file.directory:
    - name: {{ jenkins.home }}/logs/nginx
    - mode: 0775
    - makedirs: True
    - user: {{ jenkins.user }}
    - group: www-data

/etc/nginx/sites-available/jenkins.conf:
  file.managed:
    - template: jinja
    - source: salt://jenkins/files/nginx.conf
    - user: {{ jenkins.nginx_user }}
    - group: {{ jenkins.nginx_group }}
    - mode: 440

/etc/nginx/sites-enabled/jenkins.conf:
  file.symlink:
    - target: /etc/nginx/sites-available/jenkins.conf
    - user: {{ jenkins.nginx_user }}
    - group: {{ jenkins.nginx_group }}
    - require:
        - file: jenkins_nginx_logs

extend:
  nginx:
    service:
      - watch:
        - file: /etc/nginx/sites-available/jenkins.conf
      - require:
        - file: /etc/nginx/sites-enabled/jenkins.conf
