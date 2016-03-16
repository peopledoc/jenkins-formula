{% from 'jenkins/map.jinja' import jenkins -%}

stop_sysv:
  cmd.run:
    - name: /etc/init.d/jenkins stop
    - unless: test ! -f /etc/init.d/jenkins -o -f /etc/systemd/system/jenkins.service

service_unit:
  file.managed:
    - name: /etc/systemd/system/jenkins.service
    - source: salt://jenkins/jenkins.service
    - mode: 0644
    - template: jinja
    - defaults:
        blockioweight: {{ jenkins.master.blockioweight }}
        cpuquota: {{ jenkins.master.cpuquota }}

daemon_reload:
  cmd.wait:
    - name: systemctl daemon-reload
    - watch:
        - file: service_unit
