# -*- coding: utf-8 -*-
import os
import xml.etree.ElementTree as ET

import salt.exceptions as exc


def managed(name, text='', create=False, **kwargs):
    """Manages jenkins config content for a given xpath.

    name
        The xpath to be managed.

    text
        The content to set at the given xpath.

    create
        Creates element for the given xpath if not exist (NOT IMPLEMENTED).
    """

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    formatdiff = __salt__['jenkins.formatdiff']  # noqa
    home = __pillar__['jenkins'].get('home', '/var/lib/jenkins')  # noqa
    test = __opts__['test']  # noqa

    config_path = os.path.join(home, 'config.xml')
    config = ET.parse(config_path)

    if config.find(name) is None and not create:
        ret['comment'] = '`{0}` not found.'.format(name)
        return ret

    old = ET.tostring(config.find('.'))
    config.find(name).text = str(text)
    diff = formatdiff(old, new=ET.tostring(config.find('.')))
    if diff:
        ret['changes']['diff'] = diff

    if not test:
        config.write(config_path)

    ret['result'] = None if test else True
    return ret


def reloaded(name):

    ret = {
        'name': name,
        'changes': {
            'old': '',
            'new': 'done',
        },
        'result': False,
        'comment': ''
    }

    _runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    if not test:
        try:
            _runcli('reload-configuration')
        except exc.CommandExecutionError as e:
            ret['comment'] = e.message
            return ret
    else:
        pass

    ret['result'] = None if test else True
    return ret
