{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}

include:
  - python

jenkinsapi:
  virtualenv.managed:
    - name: {{ home }}/.virtualenvs/jenkinsapi
    - user: jenkins
    - group: jenkins
    - requirements: salt://jenkins/api/requirements.pip
    - require:
      - user: jenkins_user
