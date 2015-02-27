# -*- coding: utf-8 -*-
import logging

log = logging.getLogger(__name__)

JENKINS_URL = 'http://127.0.0.1:8080'


def runcli(cmd, extras=None):

    cmd = '/usr/local/bin/jenkins-cli {0}'.format(cmd)
    log.debug(cmd)

    extras = extras or []

    import subprocess
    p = subprocess.Popen(cmd.split(' ') + extras, stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)

    return p.communicate()


def restart(jenkins_url=None, wait_online=True):
    """Restarts jenkins and returns stderr or None.

    jenkins_url
        Jenkins url for wait online check (default: http://127.0.0.1:8080).

    wait_online
        Boolean flag if we want to wait online after install (default: True).
    """

    stdout, stderr = runcli('safe-restart')
    if stderr or not wait_online:
        return stderr

    # wait
    import itertools
    import requests
    import time
    max_tries = 10 
    count = itertools.count()  
    while count.next() < 10:
        try:
            response = requests.get(jenkins_url or JENKINS_URL)
        except requests.ConnectionError:
            pass
        # sleep between tries and last 200
        time.sleep(2)
        # ok
        if response.status_code == 200:
            break
