{% from 'jenkins/map.jinja' import jenkins -%}

{%- if jenkins.views %}
views_present:
  jenkins_view.present:
    - names: {{ jenkins.views.names }}
{%- if jenkins.views.columns %}
    - columns: {{ jenkins.views.columns }}
{%- endif %}
{%- endif %}
