{% from 'jenkins/map.jinja' import jenkins -%}

git:
  pkg.installed:
    - reload_modules: True

dotssh_dir:
  file.directory:
    - name: {{ jenkins.home }}/.ssh
    - mode: 0700
    - user: {{ jenkins.user }}
    - group: {{ jenkins.group }}

git_key:
  file.managed:
    - name: {{ jenkins.home }}/.ssh/id_rsa_git
    - contents_pillar: jenkins:git:prvkey
    - mode: 0600
    - user: {{ jenkins.user }}
    - group: {{ jenkins.group }}

ssh_config_mode:
  file.managed:
    - name: {{ jenkins.home }}/.ssh/config
    - user: {{ jenkins.user }}
    - group: {{ jenkins.group }}
    - mode: 0600

{% for host in jenkins.git.hosts -%}
{% if not salt['ssh.get_known_host'](jenkins.user, host) -%}
git_host_{{ host }}_known:
  module.run:
    - name: ssh.set_known_host
    - hostname: {{ host }}
    - user: {{ jenkins.user }}
{%- endif %}

git_host_{{ host }}_setup:
  file.append:
    - name: {{ jenkins.home }}/.ssh/config
    - text: |
        Host {{ host }}
             Identityfile ~/.ssh/id_rsa_git
{%- endfor %}
