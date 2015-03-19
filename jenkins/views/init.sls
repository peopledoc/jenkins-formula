{% set jenkins = pillar.get('jenkins', {}) -%}
{% set views = jenkins.get('views', {}) -%}
{% set present = views.get('present', []) -%}
{% set absent = views.get('absent', []) -%}

{%- if absent %}
views_absent:
  jenkins_views.absent:
    - names:
{%- for name in absent %}
      - {{ name }}
{%- endfor %}
{%- endif %}

{%- if present %}
views_present:
  jenkins_views.present:
    - names:
{%- for view in present %}
      - {{ view }}
{%- endfor %}
{%- endif %}
