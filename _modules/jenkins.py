# -*- coding: utf-8 -*-

import logging
import subprocess

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
