{% set jenkins = pillar.get('jenkins', {}) -%}
{% set plugins = jenkins.get('plugins', {}) -%}
{% set installed = plugins.get('installed', []) -%}
{% set removed = plugins.get('removed', []) -%}

{% if installed -%}
remove_installed_plugins:
  jenkins_plugins:
    - removed
    - names:
{% for name in installed %}
      - {{ name }}
{% endfor -%}
{% endif %}

{% if removed -%}
reinstall_removed_plugins:
  jenkins_plugins:
    - installed
    - names:
{% for name in removed %}
      - {{ name }}
{% endfor -%}
{% endif %}

restart_after_uninstall:
  jenkins:
    - restart
    - watch:
{% if installed %}
      - jenkins_plugins: remove_installed_plugins
{% endif %}
{% if removed %}
      - jenkins_plugins: reinstall_removed_plugins
{% endif %}
