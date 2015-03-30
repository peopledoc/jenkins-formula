# -*- coding: utf-8 -*-
import os
import re
import shutil

import salt.exceptions as exc


def _update(name, skiped=None, updateall=True):  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    update_list = [] if updateall else [name]
    skiped = skiped or []

    runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    try:
        stdout = runcli('list-plugins')
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

        name, current, update = m.groups()
        # no need to update
        if update_list and name not in update_list:
            continue
        # skiped
        if name in skiped:
            continue

        if not test:
            try:
                runcli('install-plugin', name)
            except exc.CommandExecutionError as e:
                ret['comment'] = e.message
                return ret
        else:
            pass

        ret['changes'][name] = {
            'old': current,
            'new': update,
        }

    return ret


(
    IS_INSTALLED,
    NOT_AVAILABLE
) = range(2)


def _info(name):

    # get info
    runcli = __salt__['jenkins.runcli']  # noqa
    stdout = runcli('list-plugins {0}'.format(name))

    # check info
    RE_INSTALL = '(\w.+?)\s.*\s(\d+.*)'
    m = re.match(RE_INSTALL, stdout)
    if not m:
        return NOT_AVAILABLE, 'Invalid info for {0}: {1}'.format(name, stdout)

    __, version = m.groups()
    return IS_INSTALLED, version


def installed(name):
    """Ensures jenkins plugins are present.

    name
        The name of one specific plugin to ensure.
    """
    ret = _update(name, updateall=False)

    runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    # just updated
    if name in ret['changes']:
        ret['result'] = None if test else True
        return ret

    # get info before install
    try:
        status, info = _info(name)
    except exc.CommandExecutionError as e:
        ret['comment'] = e.message
        return ret

    # installed
    if status == IS_INSTALLED:
        ret['result'] = None if test else True
        return ret

    # install
    if not test:
        try:
            runcli('install-plugin {0}'.format(name))
        except exc.CommandExecutionError as e:
            ret['comment'] = e.message
            return ret
    else:
        pass

    # fresh install
    ret['changes'] = {
        'old': None,
        'new': True,
    }

    ret['result'] = None if test else True
    return ret


def _uninstall(name):

    result = []

    home = __pillar__['jenkins'].get('home', '/var/lib/jenkins')  # noqa
    plugin_dir = os.path.join(home, 'plugins')

    test = __opts__['test']  # noqa

    for item in os.listdir(plugin_dir):
        # next
        if not item.startswith(name):
            continue
        # remove
        path = os.path.join(plugin_dir, item)
        if item == name and os.path.isdir(path):
            if not test:
                shutil.rmtree(path)
            result.append(path)
        elif item in ['{0}{1}'.format(name, ext) for ext in ['.hpi', '.jpi']]:
            if not test:
                os.remove(path)
            result.append(path)

    return result


def removed(name):

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    # get info before install
    try:
        status, info = _info(name)
    except exc.CommandExecutionError as e:
        ret['comment'] = e.message
        return ret

    # removed
    if status == IS_INSTALLED and _uninstall(name):
        ret['changes'] = {
            'old': info,
            'new': None,
        }

    ret['result'] = None if __opts__['test'] else True  # noqa
    return ret


def updated(name, skiped=None, updateall=True):
    """Updates jenkins plugins.

    name
        The name of one specific plugin to update

    skiped
        The names of plugins to skiped from update.

    updateall
        Boolean flag if we want to update all the updateable plugins
        (default: True).
    """
    test = __opts__['test']  # noqa

    ret = _update(name, skiped=skiped, updateall=updateall)

    ret['result'] = None if test else True
    return ret
