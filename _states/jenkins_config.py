# -*- coding: utf-8 -*-
import os
import xml.etree.ElementTree as ET

import salt.exceptions as exc


def managed(name, text='', create=False):
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
    # load config
    home = __pillar__['jenkins'].get('home', '/var/lib/jenkins')  # noqa
    test = __opts__['test']  # noqa

    config_path = os.path.join(home, 'config.xml')

    if not os.path.exists(config_path):
        ret['comment'] = 'Path `{0}` not found.'.format(config_path)
        return ret

    config = ET.parse(config_path)

    # check exist
    if config.find(name) is None and not create:
        ret['comment'] = '`{0}` not found.'.format(name)
        return ret

    old = ET.tostring(config.find('.'))
    config.find(name).text = str(text)
    ret['changes'] = {
        'diff': formatdiff(old, new=ET.tostring(config.find('.'))),
    }

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
