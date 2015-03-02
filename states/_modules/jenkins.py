# -*- coding: utf-8 -*-
import logging
import subprocess
import itertools
import requests
import time

import salt.exceptions as exc


log = logging.getLogger(__name__)

JENKINS_URL = 'http://127.0.0.1:8080'


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


def restart(jenkins_url=None, wait_online=True):
    """Restarts jenkins and returns stderr or None.

    jenkins_url
        Jenkins url for wait online check (default: http://127.0.0.1:8080).

    wait_online
        Boolean flag if we want to wait online after install (default: True).
    """

    runcli('safe-restart')

    if not wait_online:
        return

    url = jenkins_url or JENKINS_URL
    count = itertools.count()
    while count.next() < 30:
        try:
            response = requests.head(url)
        except requests.ConnectionError:
            pass
        # sleep between tries and last on 200
        time.sleep(1)
        if response.status_code == 200:
            return
    raise exc.CommandExecutionError('Jenkins fails to reload in time')
