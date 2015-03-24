# -*- coding: utf-8 -*-
import difflib
import logging
import subprocess

import xml.etree.ElementTree as ET

import salt.exceptions as exc


log = logging.getLogger(__name__)


def runcli(*args, **kwargs):
    args = ('/usr/local/sbin/jenkins-cli',) + args

    p = subprocess.Popen(
        args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        stdin=subprocess.PIPE)

    input_ = kwargs.get('input_')
    if input_:
        p.stdin.write(input_)
    p.stdin.close()
    p.wait()

    if p.returncode != 0:
        raise exc.CommandExecutionError(p.stderr.read())

    return p.stdout.read()


def restart(wait_online=True):
    """Restarts jenkins and returns stderr or None.

    wait_online
        Boolean flag if we want to wait online after install (default: True).
    """

    runcli('safe-restart')

    if wait_online:
        runcli('wait-master-online')

def update_xml(name, action, xml, old):
    """Updates old xml payload with new one for a given action, ex: view, ...

    name
        The result name.

    action
        The update action name, ex: view, node, etc.

    xml
        The xml payload to update or not if not changed.

    old
        The old xml payload to compare with.
    """

    test = __opts__['test']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    # serialize new payload
    new = """<?xml version="1.0" encoding="UTF-8"?>\n"""
    new += ET.tostring(xml.find('.'))
    # Follow jenkins-cli convention
    new = new.replace(" />", "/>")

    if old == new:
        ret['comment'] = 'No changes'
        ret['result'] = True
        return ret

    diff = '\n'.join(difflib.unified_diff(
        old.splitlines(), new.splitlines()))

    ret['changes'] = {
        'diff': diff,
    }

    if test:
        ret['result'] = None
        return ret

    # update if not testing
    try:
        runcli('update-{0}'.format(action), name, input_=new)
    except exc.CommandExecutionError as e:
        ret['comment'] = e.message
        return ret

    ret['result'] = True
    return ret
