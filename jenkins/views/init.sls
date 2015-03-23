{% set jenkins = pillar.get('jenkins', {}) -%}
{% set views = jenkins.get('views', {}) -%}
{% set names = views.get('names', []) -%}
{% set columns = views.get('columns', []) -%}
{% set default = views.get('default', 'All') -%}

{%- if views %}
views_present:
  jenkins_views.present:
    - names:
{%- for name in names %}
      - {{ name }}
{%- endfor %}
{%- if columns %}
    - columns:
{%- for column in columns %}
      - {{ column }}
{%- endfor %}
{%- endif %}
{%- endif %}

config_views:
  jenkins_config.managed:
    - name: primaryView
    - text: {{ default }}
    - require:
      - jenkins_views: views_present

config_views_reload:
  jenkins_config.reloaded:
    - require:
      - jenkins_config: config_views
