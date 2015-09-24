include:
  - jenkins.install
  - jenkins.cli
  - jenkins.plugins
  - jenkins.views
  - jenkins.master.config
  - jenkins.master.ssh
  - jenkins.master.credentials
  - jenkins.git

jenkins_safe_restart:
  jenkins.restart:
    - watch:
      - cmd: jenkins_config_modified
      - cmd: jenkins_credentials_modified
