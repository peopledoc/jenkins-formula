{% set jenkins = pillar.get('jenkins', {}) -%}
{% set views = jenkins.get('views', {}) -%}
{% set names = views.get('names', []) -%}

restore_config_views:
  jenkins_config.managed:
    - name: primaryView
    - text: All

restore_config_views_reload:
  jenkins_config.reloaded:
    - require:
      - jenkins_config: restore_config_views

{%- if names %}
views_absent:
  jenkins_views.absent:
    - names:
{%- for name in names %}
      - {{ name }}
{%- endfor %}
    - require:
      - jenkins_config: restore_config_views_reload
{%- endif %}
