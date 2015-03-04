include:
  - supervisor.service

nodejs:
  pkg.installed

node_link:
  file.symlink:
    - name: /usr/bin/node
    - target: /usr/bin/nodejs
    - require:
      - pkg: nodejs

npm:
  cmd.run:
    - name: curl https://www.npmjs.com/install.sh | sh
    - require:
      - file: node_link

hookforward:
  cmd.run:
    - name: npm install -g hookforward
    - require:
      - cmd: npm
