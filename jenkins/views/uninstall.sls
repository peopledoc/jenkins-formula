{% set jenkins = pillar.get('jenkins', {}) -%}
{% set views = jenkins.get('views', {}) -%}
{% set present = views.get('present', []) -%}

{% if present -%}
views_uninstall:
  jenkins_views.absent:
    - names:
{% for name in present %}
      - {{ name }}
{% endfor -%}
{% endif %}
