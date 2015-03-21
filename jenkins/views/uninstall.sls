{% set jenkins = pillar.get('jenkins', {}) -%}
{% set views = jenkins.get('views', {}) -%}
{% set names = views.get('names', []) -%}

{%- if names %}
views_absent:
  jenkins_views.absent:
    - names:
{%- for name in names %}
      - {{ name }}
{%- endfor %}
{%- endif %}
