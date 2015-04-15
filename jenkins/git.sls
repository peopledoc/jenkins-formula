{% set jenkins = pillar.get('jenkins', {}) -%}
{% set home = jenkins.get('home', '/usr/local/jenkins') -%}
{% set user = jenkins.get('user', 'jenkins') -%}
{% set group = jenkins.get('user', user) -%}
{% set git = jenkins.get('git', {}) -%}
{% set git_hosts = git.get('hosts', []) -%}

git:
  pkg.installed:
    - reload_modules: True

dotssh_dir:
  file.directory:
    - name: {{ home }}/.ssh
    - mode: 0700
    - user: {{ user }}
    - group: {{ group }}

git_key:
  file.managed:
    - name: {{ home }}/.ssh/id_rsa_git
    - contents_pillar: jenkins:git:prvkey
    - mode: 0600
    - user: {{ user }}
    - group: {{ group }}

ssh_config_mode:
  file.managed:
    - name: {{ home }}/.ssh/config
    - user: {{ user }}
    - group: {{ group }}
    - mode: 0600

{% for host in git_hosts -%}
{% if not salt['ssh.get_known_host'](user, host) -%}
git_host_{{ host }}_known:
  module.run:
    - name: ssh.set_known_host
    - hostname: {{ host }}
    - user: {{ user }}
{%- endif %}

git_host_{{ host }}_setup:
  file.append:
    - name: {{ home }}/.ssh/config
    - text: |
        Host {{ host }}
             Identityfile ~/.ssh/id_rsa_git
{%- endfor %}
