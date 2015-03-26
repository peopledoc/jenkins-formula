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


def update_or_create_xml(name, xml, old=None,
                         object_=None, get=None, create=None, update=None):
    runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    get = get or 'get-%s' % object_

    if type(xml) in (str, unicode):
        xml = ET.fromstring(xml)

    new = """<?xml version="1.0" encoding="UTF-8"?>\n"""
    new += ET.tostring(xml.find('.'), encoding='utf-8')
    # Follow jenkins-cli convention
    new = new.replace(" />", "/>")

    try:
        if old is None:
            old = runcli(get, name)
        # Jenkins sometimes returns \n after <?xml
        old = old.replace("?><", "?>\n<")
    except Exception:
        old = ''
        command = create or 'create-%s' % object_
    else:
        command = update or 'update-%s' % object_

    if new == old:
        ret['comment'] = 'Not changed.'
        ret['result'] = True
        return ret

    diff = difflib.unified_diff(old.splitlines(True), new.splitlines(True),
                                fromfile='old', tofile='new')
    diff = list(diff)
    last_line = diff[-1]
    if not last_line.endswith('\n'):
        last_line += '\n\ No newline at end of file\n'
    diff[-1] = last_line
    ret['changes']['diff'] = ''.join(diff)

    if test:
        ret['result'] = None
        return ret

    # update if not testing
    try:
        runcli(command, name, input_=new)
    except exc.CommandExecutionError as e:
        ret['comment'] = e.message
        return ret

    ret['result'] = True
    return ret
