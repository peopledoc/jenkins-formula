# -*- coding: utf-8 -*-

RE_UPDATED = '(\w.+?)\s.*\s(\d+.*) \((.*)\)'


def updated(name, jenkins_url=None, pkgs=None, restart=True, updateall=True,
            wait_online=True, **kwargs):
    """Updates jenkins plugins.

    name
        The name of one specific plugin to update

    jenkins_url
        Jenkins url for wait online check (default: http://127.0.0.1:8080).

    pkgs
        The names of specifics plugins to update.

    restart
        Boolean flag if we want to restart after install (default: True).

    updateall
        Boolean flag if we want to update all the updateable plugins
        (default: True).

    wait_online
        Boolean flag if we want to wait online after install (default: True).
    """
    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    _runcli = __salt__['jenkins.runcli']

    # list
    stdout, stderr = _runcli('list-plugins')
    if stderr:
        ret['comment'] = stderr
        return ret

    # update
    import re
    for l in stdout.strip().split('\n'):

        m = re.match(RE_UPDATED, l)
        # not match with ex.: 'maven-plugin  Maven plugin  2.7.1 (2.8)'
        if not m:
            continue
        short_name, current, update = m.groups()
        ret['changes'][short_name] = {
            'old': current,
            'new': update,
        }

        stdout, stderr = _runcli('install-plugin {0}'.format(short_name))
        if stderr:
            ret['comment'] = stderr
            return ret

    # not restart
    ret['result'] = True
    if not restart or not ret['changes']:
        return ret

    _restart = __salt__['jenkins.restart']

    # restart
    stderr = _restart(jenkins_url=jenkins_url, wait_online=wait_online)
    if stderr:
        ret['comment'] = stderr
        ret['result'] = False
        return ret

    return ret
