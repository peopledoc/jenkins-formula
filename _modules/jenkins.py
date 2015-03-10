# -*- coding: utf-8 -*-

import base64
from hashlib import sha256
import itertools
import logging
import os.path
import re
import requests
import subprocess
import time

import salt.exceptions as exc

from Crypto.Cipher import AES


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


def encrypt_credentials(home):
    # Find all credentials to encrypt
    credentials_path = os.path.join(home, 'credentials.xml')
    credentials_xml = open(credentials_path).read()
    credentials = {}
    for match in re.findall(r"ENCRYPT\('(.*?)'\)", credentials_xml):
        credentials[match] = None

    # Setup cipher
    magic = "::::MAGIC::::"
    master_key = open(os.path.join(home, 'secrets', 'master.key')).read()
    hudson_secret_key = open(os.path.join(
        home, 'secrets', 'hudson.util.Secret')).read()

    # https://github.com/jenkinsci/jenkins/blob/master/core/src/main/java/hudson/Util.java#L628
    hashed_master_key = sha256(master_key).digest()[:16]
    # https://github.com/jenkinsci/jenkins/blob/master/core/src/main/java/jenkins/security/DefaultConfidentialStore.java#L97
    cipher = AES.new(hashed_master_key, AES.MODE_ECB)
    hudson_secret_key = cipher.decrypt(hudson_secret_key)[:16]
    cipher = AES.new(hudson_secret_key, AES.MODE_ECB)

    # Encrypt all password and replace
    for password in credentials.keys():
        data = password + magic
        pad_len = 16 - (len(data) % 16)
        data += '\x0f' * pad_len
        data = cipher.encrypt(data)
        data = base64.b64encode(data)
        needle = "ENCRYPT('"+password+"')"
        credentials_xml = credentials_xml.replace(needle, data)

    # Save encrypted passwords
    open(credentials_path, 'w').write(credentials_xml)
    return True
