# -*- coding: utf-8 -*-
import re


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
    _runcli = __salt__['jenkins.runcli']  # noqa
    _restart = __salt__['jenkins.restart']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    try:
        stdout = _runcli('list-plugins')
    except Exception, e:
        ret['comment'] = e.message
        return ret

    # match with ex.: 'maven-plugin  Maven plugin  2.7.1 (2.8)'
    RE_UPDATED = '(\w.+?)\s.*\s(\d+.*) \((.*)\)'

    for l in stdout.strip().split('\n'):
        m = re.match(RE_UPDATED, l)
        if not m:
            # no need to update
            continue
        short_name, current, update = m.groups()
        ret['changes'][short_name] = {
            'old': current,
            'new': update,
        }

        try:
            _runcli('install-plugin', short_name)
        except Exception, e:
            ret['comment'] = e.message
            return ret

    ret['result'] = True
    if not restart or not ret['changes']:
        return ret

    try:
        _restart(jenkins_url=jenkins_url, wait_online=wait_online)
    except Exception, e:
        ret['comment'] = e.message
        ret['result'] = False
        return ret

    return ret
