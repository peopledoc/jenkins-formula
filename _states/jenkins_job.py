# -*- coding: utf-8 -*-

import os


def present(name, source, template=None, context=None):
    update_or_create_xml = __salt__['jenkins.update_or_create_xml']  # noqa
    get_file_str = __salt__['cp.get_file_str']  # noqa
    get_template = __salt__['cp.get_template']  # noqa

    if template:
        get_template(source, '/tmp/job.xml', template=template,
                     context=context)
        new = open('/tmp/job.xml').read().strip()
        os.unlink('/tmp/job.xml')
    else:
        new = get_file_str(source)

    return update_or_create_xml(name, new, object_='job')


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
