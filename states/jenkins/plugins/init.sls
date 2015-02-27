{% set jenkins = pillar.get('jenkins', {}) -%}
{% set plugins = jenkins.get('plugins', []) -%}

install_plugins:
  jenkins_plugins:
    - installed
    - names:
{% for name in plugins %}
      - {{ name }}
{% endfor -%}

update_plugins:
  jenkins_plugins:
    - updated
