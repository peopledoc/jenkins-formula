# -*- coding: utf-8 -*-

import logging
import os
import re
import shutil

import salt.exceptions as exc


logger = logging.getLogger(__name__)


(
    UNINSTALLED,
    INSTALLED,
    UPGRADABLE,
) = range(3)


# Sample output ouf `list-plugins`
#
# translation                   Translation Assistance plugin         1.12
# maven-plugin                  Maven Integration plugin              2.7.1 (2.12.1)  # noqa
#
_list_re = re.compile(
    '(?P<name>\S+)'
    '.*?'
    '(?P<installed>\d[\d.]*)'
    '(?: \((?P<available>\d[\d.-]*)\))?'
    '\n',
)


def _info(name):
    runcli = __salt__['jenkins.runcli']  # noqa
    try:
        stdout = runcli('list-plugins {0}'.format(name))
    except exc.CommandExecutionError as e:
        if 'ERROR: No plugin with the name' in e.message:
            return UNINSTALLED, 'Error in listing {}'.format(name), None
        else:
            raise

    m = _list_re.match(stdout)
    if not m:
        return UNINSTALLED, '{} not found'.format(name), None

    _, installed, available = m.groups()

    if available:
        return UPGRADABLE, installed, available

    return INSTALLED, installed, None


def _install(name, current_version=None, available_version=None):
    ret = {
        'name': name,
        'changes': {
            'old': current_version or 'uninstalled',
            'new': available_version or True,
        },
        'result': False,
        'comment': 'Would install %s' % (name,)
    }

    runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    if not test:
        try:
            runcli('install-plugin', name)
        except exc.CommandExecutionError as e:
            ret['comment'] = "Failed to install plugins: %s" % (e.message,)
            return ret
        else:
            ret['comment'] = 'Plugin installed successfully'

    ret['result'] = None if test else True
    return ret


def installed(name, update=False):
    """Ensures jenkins plugins are present.

    name
        The name of one specific plugin to ensure.
    """
    ret = {
        'name': name,
        'result': False,
        'comment': '',
        'changes': {},
    }

    runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    if name.endswith('.hpi'):
        plugin_name = os.path.basename(name[:-4])
    else:
        plugin_name = name
    try:
        status, installed, available = _info(plugin_name)
    except exc.CommandExecutionError as e:
        ret['comment'] = e.message
        return ret

    if status == UNINSTALLED:
        ret = _install(name)
    elif status == INSTALLED:
        ret['comment'] = 'Already installed'
        ret['result'] = True
    elif status == UPGRADABLE:
        if update:
            ret = _install(name, installed, available)
        else:
            ret['comment'] = 'Not updated'
            ret['result'] = True

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
    if status == INSTALLED and _uninstall(name):
        ret['changes'] = {
            'old': info,
            'new': None,
        }

    ret['result'] = None if __opts__['test'] else True  # noqa
    return ret


def updated(name, skipped=None, updateall=True):
    """Updates jenkins plugins.

    name
        The name of one specific plugin to update

    skipped
        The names of plugins to skipped from update.

    updateall
        Boolean flag if we want to update all the updateable plugins
        (default: True).
    """
    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    update_list = [] if updateall else [name]
    skipped = skipped or []

    runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    try:
        stdout = runcli('list-plugins')
    except exc.CommandExecutionError as e:
        ret['comment'] = "Failed to list plugins: %r" % (e.message,)
        return ret

    for line in stdout.splitlines():
        m = _list_re.match(line)
        if not m:
            continue

        name, current, update = m.groups()
        if update_list and name not in update_list:
            continue

        if not update:
            continue

        if name in skipped:
            logger.debug("%s %s available, but skipping", name, update)
            continue

        if not test:
            try:
                runcli('install-plugin', name)
            except exc.CommandExecutionError as e:
                ret['comment'] = "Failed to instal plugins: %s" % (e.message,)
                return ret

        ret['changes'][name] = {
            'old': current,
            'new': update,
        }

    ret['comment'] = 'Plugins uptodate'
    ret['result'] = None if test and ret['changes'] else True
    return ret
