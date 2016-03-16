{% from 'jenkins/map.jinja' import jenkins -%}

jenkins_user:
  user.present:
    - name: {{ jenkins.user }}
    - home: {{ jenkins.home }}
