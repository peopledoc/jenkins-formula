{% set jenkins = pillar.get('jenkins', {}) -%}
{% set plugins = jenkins.get('plugins', {}) -%}
{% set installed = plugins.get('installed', []) -%}
{% set removed = plugins.get('removed', []) -%}
{% set skipped = plugins.get('skipped', []) -%}

{% set java_security = '/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/security/java.security' -%}
{% if salt['file.file_exists'](java_security) -%}
allow_md5_algorithm:
  file.replace:
    - name: {{ java_security }}
    - pattern: ^jdk.certpath.disabledAlgorithms.*
    - repl: jdk.certpath.disabledAlgorithms=MD2, RSA keySize < 512

jenkins_plugins_safe_restart:
  jenkins.restart:
    - watch:
      - file: allow_md5_algorithm
{%- endif %}

{% if removed -%}
remove_plugins:
  jenkins_plugins.removed:
    - names:
{%- for name in removed %}
      - {{ name }}
{%- endfor %}
{%- endif %}

{% if installed -%}
install_plugins:
  jenkins_plugins.installed:
    - names:
{%- for name in installed %}
      - {{ name }}
{%- endfor %}
{%- endif %}

update_plugins:
  jenkins_plugins:
    - updated
{%- if skipped %}
    - skipped:
{%- for name in skipped %}
      - {{ name }}
{%- endfor %}
{%- endif %}

restart_after_install:
  jenkins.restart:
    - watch:
{%- if removed %}
      - jenkins_plugins: remove_plugins
{%- endif %}
{%- if installed %}
      - jenkins_plugins: install_plugins
{%- endif %}
      - jenkins_plugins: update_plugins
