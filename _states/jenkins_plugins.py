# -*- coding: utf-8 -*-
import os
import re
import shutil

import salt.exceptions as exc


def _update(name, names=None, skiped=None, updateall=True):  # noqa

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

    skiped = skiped or []

    _runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa
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
        # skiped
        if short_name in skiped:
            continue

        if not test:
            try:
                _runcli('install-plugin', short_name)
            except exc.CommandExecutionError as e:
                ret['comment'] = e.message
                return ret
        else:
            pass

        ret['changes'][short_name] = {
            'old': current,
            'new': update,
        }

    ret['result'] = None if test else True
    return ret


(
    IS_INSTALLED,
    NOT_AVAILABLE
) = range(2)


def _info(short_name):

    # get info
    _runcli = __salt__['jenkins.runcli']  # noqa
    stdout = _runcli('list-plugins {0}'.format(short_name))

    # check info
    RE_INSTALL = '(\w.+?)\s.*\s(\d+.*)'
    m = re.match(RE_INSTALL, stdout)
    if not m:
        return NOT_AVAILABLE, 'Invalid info for {0}: {1}'.format(short_name,
                                                                 stdout)

    __, version = m.groups()
    return IS_INSTALLED, version


def installed(name, names=None, **kwargs):
    """Ensures jenkins plugins are present.

    name
        The name of one specific plugin to ensure.

    names
        The names of specifics plugins to ensure.
    """
    ret = _update(name, names=names, updateall=False)

    if not names:
        names = [name]

    _runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa
    for short_name in names:

        # just updated
        if short_name in ret['changes']:
            continue

        # get info before install
        try:
            status, info = _info(short_name)
        except exc.CommandExecutionError as e:
            ret['comment'] = e.message
            return ret

        # installed
        if status == IS_INSTALLED:
            continue

        # install
        if not test:
            try:
                _runcli('install-plugin {0}'.format(short_name))
            except exc.CommandExecutionError as e:
                ret['comment'] = e.message
                return ret
        else:
            pass

        # fresh install
        ret['changes'][short_name] = {
            'old': None,
            'new': True,
        }

    ret['result'] = None if test else True
    return ret


def _uninstall(short_name):

    result = []

    home = __pillar__['jenkins'].get('home', '/var/lib/jenkins')  # noqa
    plugin_dir = os.path.join(home, 'plugins')

    test = __opts__['test']  # noqa

    for item in os.listdir(plugin_dir):
        # next
        if not item.startswith(short_name):
            continue
        # remove
        path = os.path.join(plugin_dir, item)
        if item == short_name and os.path.isdir(path):
            if not test:
                shutil.rmtree(path)
            result.append(path)
        elif item in ['{0}{1}'.format(short_name, ext) for ext in ['.hpi', '.jpi']]:  # noqa
            if not test:
                os.remove(path)
            result.append(path)

    return result


def removed(name, names=None):

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    if not names:
        names = [name]

    for short_name in names:

        # get info before install
        try:
            status, info = _info(short_name)
        except exc.CommandExecutionError as e:
            ret['comment'] = e.message
            return ret

        # removed
        if status == IS_INSTALLED and _uninstall(short_name):
            ret['changes'][short_name] = {
                'old': info,
                'new': None,
            }

    ret['result'] = None if __opts__['test'] else True  # noqa
    return ret


def updated(name, names=None, skiped=None, updateall=True, **kwargs):
    """Updates jenkins plugins.

    name
        The name of one specific plugin to update

    names
        The names of specifics plugins to update.

    skiped
        The names of plugins to skiped from update.

    updateall
        Boolean flag if we want to update all the updateable plugins
        (default: True).
    """
    return _update(name, names=names, skiped=skiped, updateall=updateall)
