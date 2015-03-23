# -*- coding: utf-8 -*-

import os
import difflib


def present(name, source, template=None, context=None):

    _runcli = __salt__['jenkins.runcli']  # noqa
    _get_file_str = __salt__['cp.get_file_str']  # noqa
    _get_template = __salt__['cp.get_template']  # noqa
    test = __opts__['test']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': None if test else True,
        'comment': ''
    }

    if template:
        _get_template(source, '/tmp/job.xml', template=template,
                      context=context)
        new = open('/tmp/job.xml').read()
        os.unlink('/tmp/job.xml')
    else:
        new = _get_file_str(source)

    try:
        current = _runcli('get-job', name)
    except Exception:
        current = ''
        command = 'create-job'
    else:
        command = 'update-job'

    if new == current:
        ret['comment'] = 'Job not changed.'
        return ret

    if not test:
        try:
            ret['comment'] = _runcli(command, name, input_=new)
        except Exception, e:
            ret['comment'] = e.message
            ret['result'] = False
            return ret

    diff = '\n'.join(difflib.unified_diff(
        current.splitlines(), new.splitlines()))

    ret['comment'] = 'Changed'
    ret['changes'] = {
        'diff': diff,
    }
    return ret


def absent(name):

    _runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': None if test else True,
        'comment': ''
    }

    try:
        _runcli('get-job', name)
    except Exception:
        ret['comment'] = 'Already removed'
        return ret

    if not test:
        try:
            ret['comment'] = _runcli('delete-job', name)
        except Exception, e:
            ret['comment'] = e.message
            ret['result'] = False
            return ret

    ret['changes'] = {
        'old': 'present',
        'new': 'absent',
    }
    return ret
