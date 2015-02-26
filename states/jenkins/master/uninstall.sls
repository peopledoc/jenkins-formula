include:
  - jenkins.cli.uninstall

remove_site:
  file.absent:
    - name: /etc/nginx/sites-available/jenkins.conf

remove_site_link:
  file.absent:
    - name: /etc/nginx/sites-enabled/jenkins.conf

remove_pkgs:
  pkg.purged:
    - pkgs:
      - jenkins
      - nginx-full
