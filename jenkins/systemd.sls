{# Defaults to 50% of all CPU available -#}
{% set default_cpuquota = '%s%%' % (50.0 * grains['num_cpus']) -%}
{% set cpuquota = salt['grains.get']('jenkins:cpuquota', default_cpuquota) -%}
{% set blockioweight = salt['grains.get']('jenkins:blockioweight', 800) -%}

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
        blockioweight: {{ blockioweight }}
        cpuquota: {{ cpuquota }}

daemon_reload:
  cmd.wait:
    - name: systemctl daemon-reload
    - watch:
        - file: service_unit
