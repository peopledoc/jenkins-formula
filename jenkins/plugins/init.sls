{% set jenkins = pillar.get('jenkins', {}) -%}
{% set plugins = jenkins.get('plugins', {}) -%}
{% set installed = plugins.get('installed', []) -%}
{% set removed = plugins.get('removed', []) -%}
{% set skiped = plugins.get('skiped', []) -%}

{% if removed -%}
remove_plugins:
  jenkins_plugins:
    - removed
    - names:
{% for name in removed %}
      - {{ name }}
{% endfor -%}
{% endif %}

{% if installed -%}
install_plugins:
  jenkins_plugins:
    - installed
    - names:
{% for name in installed %}
      - {{ name }}
{% endfor -%}
{% endif %}

update_plugins:
  jenkins_plugins:
    - updated
{% if skiped %}
    - skiped:
{% for name in skiped %}
      - {{ name }}
{% endfor -%}
{% endif %}

restart_after_install:
  jenkins:
    - restart
    - watch:
{% if removed %}
      - jenkins_plugins: remove_plugins
{% endif %}
{% if installed %}
      - jenkins_plugins: install_plugins
{% endif %}
      - jenkins_plugins: update_plugins
