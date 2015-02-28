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

    stderr = __salt__['jenkins.restart'](wait_online=wait_online)
    if stderr:
        ret['comment'] = stderr
        ret['result'] = False
        return ret

    return ret
