{% from 'jenkins/map.jinja' import jenkins %}

slave_pkgs:
  pkg.latest:
    - pkgs:
        - default-jre-headless
        - ntpdate
        - openssh-server

allow_master_key:
  ssh_auth.present:
    - name: {{ jenkins.slave.master_key }}
    - user: {{ jenkins.user }}

slave_node:
  jenkins_node.present:
    - name: {{ jenkins.node.name }}
    - host: {{ jenkins.node.host }}
    - remote_fs: {{ jenkins.node.remote_fs }}
    - num_executors: {{ jenkins.node.num_executors }}
    - credential: {{ jenkins.node.credentials }}
    - labels: {{ jenkins.node.labels }}
