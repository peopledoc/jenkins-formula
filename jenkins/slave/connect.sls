{% from 'jenkins/map.jinja' import jenkins %}

jenkins_connect_node:
  jenkins_node.connected:
    - name: {{ jenkins.node.name }}