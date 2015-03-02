remove_hookforward:
  cmd.run:
    - name: npm uninstall -g hookforward
    - onlyif:
        - hookforward --version

remove_npm:
  cmd.run:
    - name: npm uninstall -g npm
    - require:
      - cmd: remove_hookforward
    - onlyif:
        - npm --version

remove_nodejs:
  pkg.purged:
    - pkgs:
      - nodejs

remove_node_link:
  file.absent:
    - name: /usr/bin/node
    - require:
      - pkg: remove_nodejs
