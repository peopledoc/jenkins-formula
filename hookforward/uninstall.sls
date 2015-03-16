
hookforward_remove:
  service.dead:
    - name: hookforward
    - enable: False
  cmd.run:
    - name: systemctl daemon-reload
  file.absent:
    - name: /etc/systemd/system/hookforward.service
  npm.removed:
    - name: hookforward
