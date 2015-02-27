{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set group = jenkins.get('group', user) -%}
{% set ssh_credential = jenkins.get('ssh_credential', '0c952d99-54de-44c4-99d8-86f2c3acf170') %}

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

# We can't use a template var, because the state is generated and sent to the
# minion before jenkins is up.
jenkins_version:
  cmd.run:
    - name: sed -i s/JENKINS_VERSION/$(/usr/local/bin/jenkins-cli version)/g {{ home }}/config.xml
    - user: jenkins
    - watch:
      - file: jenkins_config

ssh_key:
  cmd.run:
    - name: ssh-keygen -q -N '' -f {{ home }}/.ssh/id_rsa
    - user: {{ user }}
    - creates: {{ home }}/.ssh/id_rsa

jenkins_credentials:
  file.managed:
    - name: {{ home }}/credentials.xml
    - mode: 0644
    - user: {{ user }}
    - group: {{ group }}
    - template: jinja
    - source: salt://jenkins/master/credentials.xml
    - defaults:
        user: {{ user }}
        credential: {{ ssh_credential }}

jenkins_nodeMonitors:
  file.managed:
    - name: {{ home }}/nodeMonitors.xml
    - mode: 0644
    - user: {{ user }}
    - group: {{ group }}
    - source: salt://jenkins/master/nodeMonitors.xml

reload:
  cmd.run:
    # safe-restart is required by nodeMonitors
    - name: /usr/local/bin/jenkins-cli safe-restart
    - watch:
      - file: jenkins_config
      - file: jenkins_credentials
      - file: jenkins_nodeMonitors
