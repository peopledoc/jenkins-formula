# -*- coding: utf-8 -*-
import os
import difflib
import logging
import subprocess

import xml.etree.ElementTree as ET

import salt.exceptions as exc


log = logging.getLogger(__name__)


def runcli(*args, **kwargs):
    args = ('/usr/local/sbin/jenkins-cli',) + args

    if not os.path.exists(args[0]):
        raise exc.CommandExecutionError('jenkins-cli is not installed')

    log.info("Calling %r", args)
    input_ = kwargs.get('input_')
    if input_:
        try:
            input_ = input_.encode('utf-8')
        except Exception, e:
            log.debug("%r", input_)
            log.error("%s", e)

    p = subprocess.Popen(
        args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        stdin=subprocess.PIPE)

    if input_:
        p.stdin.write(input_)

    p.stdin.close()
    p.wait()

    stdout = p.stdout.read().decode('utf-8')
    log.debug(u"runcli stdout:\n%s", stdout)

    stderr = p.stderr.read().decode('utf-8')
    log.debug(u"runcli stderr:\n%s", stderr)

    if p.returncode != 0:
        message = stdout + u"\n" + stderr
        raise exc.CommandExecutionError(message)

    return stdout


def formatdiff(old, new):
    diff = difflib.unified_diff(old.splitlines(True), new.splitlines(True),
                                fromfile='old', tofile='new')
    diff = list(diff)
    if not diff:
        return

    last_line = diff[-1]
    if not last_line.endswith(u'\n'):
        last_line += u'\n\ No newline at end of file\n'
    diff[-1] = last_line
    return u''.join(diff)


def restart(wait_online=True):
    """Restarts jenkins and returns stderr or None.

    wait_online
        Boolean flag if we want to wait online after install (default: True).
    """

    runcli('safe-restart')

    if wait_online:
        runcli('wait-master-online')


def update_or_create_xml(name, xml, old=None,
                         object_=None, get=None, create=None, update=None,
                         delete=None, recreate_callback=None):
    runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    get = get or 'get-%s' % object_

    if type(xml) is unicode:
        # Wish the xml declared as UTF-8.
        xml = xml.encode('utf-8')

    if type(xml) is str:
        try:
            xml = ET.fromstring(xml)
        except Exception as e:
            ret['comment'] = str(e.message)
            ret['comment'] += '\n'
            ret['comment'] += xml.decode('utf-8')
            return ret

    new = """<?xml version="1.0" encoding="UTF-8"?>\n"""
    new += ET.tostring(xml.find('.'), encoding='utf-8')
    # Follow jenkins-cli convention
    new = new.replace(" />", "/>")
    new = new.decode('utf-8')

    try:
        if old is None:
            old = runcli(get, name)
        # Jenkins sometimes returns \n after <?xml
        old = old.replace("?><", "?>\n<")
    except Exception, e:
        log.info("Job %r not found, creation: %r", name, e)
        old = u''
        command = create or 'create-%s' % object_
    else:
        command = update or 'update-%s' % object_

    if new == old:
        ret['comment'] = 'Not changed.'
        ret['result'] = True
        return ret

    # Compat with salt.states.format_log
    ret['changes']['xmldiff'] = formatdiff(old, new).encode('utf-8')

    log.debug(u"Sending %s %s:\n%s", command, name, new)

    # Hack to overwrite job with new class
    if recreate_callback and old:
        if recreate_callback(old, new):
            log.debug(
                "Detected %s %r type change. Deleting %s first.",
                object_, name, object_
            )
            ret['comment'] = "job type changed. Old job removed."
            command = delete or 'delete-%s' % (object_,)
            try:
                if not test:
                    runcli(command, name)
            except exc.CommandExecutionError as e:
                ret['comment'] = "Failed to destroy old %s: %r" % (
                    object_, e.message,)
                return ret
            log.debug("Recreating %s %r", object_, name)
            command = create or 'create-%s' % (object_,)

    if test:
        ret['result'] = None
        return ret

    try:
        runcli(command, name, input_=new)
    except exc.CommandExecutionError as e:
        ret['comment'] = e.message
        return ret

    ret['result'] = True
    return ret
