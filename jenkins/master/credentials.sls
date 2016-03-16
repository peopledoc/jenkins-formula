{% from 'jenkins/map.jinja' import jenkins -%}

{% for name, entry in jenkins.credentials.items() -%}
credentials_{{ name }}:
  jenkins_credentials.present:
    - cls: {{ entry.cls }}
    - name: {{ entry.get('name', name) }}
    - args:
{%- for arg in entry.args %}
        - {{ arg|yaml_encode }}
{% endfor %}
    - watched_in:
        - cmd: jenkins_credentials_modified
{% endfor %}

jenkins_credentials_modified:
  cmd.wait:
    - name: "true"
