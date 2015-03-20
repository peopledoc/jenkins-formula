{% set jenkins = pillar.get('jenkins', {}) -%}
{% set views = jenkins.get('views', {}) -%}
{% set names = views.get('names', []) -%}
{% set columns = views.get('columns', []) -%}

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
