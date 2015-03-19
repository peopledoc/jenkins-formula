# -*- coding: utf-8 -*-


def restart(name, wait_online=True, **kwargs):
    """Restarts jenkins and waits it come back online or not.

    name
        The name of one specific plugin to ensure.

    wait_online
        Boolean flag if we want to wait online after install (default: True).
    """
    ret = {
        'name': name,
        'changes': {},
        'result': True,
        'comment': ''
    }

    if __opts__['test']:  # noqa
        ret['result'] = None
        return ret

    try:
        __salt__['jenkins.restart'](wait_online=wait_online)  # noqa
    except Exception, e:
        ret['comment'] = e.message
        ret['result'] = False
        return ret

    return ret
