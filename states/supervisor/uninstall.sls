{% from "supervisor/map.jinja" import supervisor, supervisor_config with context %}

stop_supervisor:
  service.dead:
    - name: {{ supervisor.service }}

remove_supervisor_include_confdir:
  file.absent:
    - name: {{ supervisor.include_confdir }}

remove_supervisor_init:
  file.absent:
    - name: /etc/init.d/supervisor

remove_supervisor_logdir:
  file.absent:
    - name: {{ supervisor.logdir }}

remove_supervisor:
  pip.removed:
    - name: supervisor
