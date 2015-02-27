{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set group = jenkins.get('group', user) -%}

include:
  - jenkins
  - jenkins.nginx
  - jenkins.cli
  - jenkins.plugins.update

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

jenkins_config:
  file.managed:
    - name: {{ home }}/config.xml
    - mode: 0644
    - user: {{ user }}
    - group: {{ group }}
    - template: jinja
    - source: salt://jenkins/master/config.xml

jenkins_version:
  cmd.run:
    - name: sed -i s/JENKINS_VERSION/$(/usr/local/bin/jenkins-cli version)/g {{ home }}/config.xml
    - user: jenkins
    - watch:
      - file: jenkins_config

jenkins_nodeMonitors:
  file.managed:
    - name: {{ home }}/nodeMonitors.xml
    - mode: 0644
    - user: {{ user }}
    - group: {{ group }}
    - template: jinja
    - source: salt://jenkins/master/nodeMonitors.xml

reload:
  cmd.run:
    # safe-restart is required by nodeMonitors
    - name: /usr/local/bin/jenkins-cli safe-restart
    - watch:
      - file: jenkins_config
      - file: jenkins_nodeMonitors

ssh_key:
  cmd.run:
    - name: ssh-keygen -q -N '' -f {{ home }}/.ssh/id_rsa
    - user: {{ user }}
    - creates: {{ home }}/.ssh/id_rsa
