{% if grains['oscodename'] != 'jessie' -%}
include:
  - supervisor.uninstall
{%- endif %}

remove_hookforward:
  npm.removed:
    - name: hookforward
