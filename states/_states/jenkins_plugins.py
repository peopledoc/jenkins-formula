# -*- coding: utf-8 -*-
import re

import salt.exceptions as exc


def _update(name, names=None, updateall=True, **kwargs):

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    if updateall:
        names = []
    elif not names:
        names = [name]

    _runcli = __salt__['jenkins.runcli']  # noqa
    try:
        stdout = _runcli('list-plugins')
    except exc.CommandExecutionError as e:
        ret['comment'] = e.message
        return ret

    # match with ex.: 'maven-plugin  Maven plugin  2.7.1 (2.8)'
    RE_UPDATE = '(\w.+?)\s.*\s(\d+.*) \((.*)\)'
    for l in stdout.strip().split('\n'):

        m = re.match(RE_UPDATE, l)
        # no need to update
        if not m:
            continue

        short_name, current, update = m.groups()
        # no need to update
        if names and short_name not in names:
            continue

        try:
            _runcli('install-plugin', short_name)
        except exc.CommandExecutionError as e:
            ret['comment'] = e.message
            return ret

        ret['changes'][short_name] = {
            'old': current,
            'new': update,
        }

    ret['result'] = True
    return ret


def installed(name, names=None, **kwargs):
    """Ensures jenkins plugins are present.

    name
        The name of one specific plugin to ensure.

    names
        The names of specifics plugins to ensure.
    """

    if not names:
        names = [names]

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    _runcli = __salt__['jenkins.runcli']
    for short_name in names:
        try:
            stdout, stderr = _runcli('install-plugin {0}'.format(short_name))
        except exc.CommandExecutionError as e:
            ret['comment'] = e.message
            return ret

    ret['result'] = True
    return ret


def updated(name, names=None, updateall=True, **kwargs):
    """Updates jenkins plugins.

    name
        The name of one specific plugin to update

    names
        The names of specifics plugins to update.

    updateall
        Boolean flag if we want to update all the updateable plugins
        (default: True).
    """
    return _update(name, names=names, updateall=updateall)
