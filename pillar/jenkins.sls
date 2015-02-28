jenkins:
  home: /var/lib/jenkins
  plugins:
    installed:
      - github
    skiped:
      - matrix-project

nginx:
  use_upstart: false
  use_sysvinit: false
