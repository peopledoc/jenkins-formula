# -*- coding: utf-8 -*-

import difflib


_create_xml_template = """\
<?xml version="1.0" encoding="UTF-8"?>
<slave>
  <name>{node_name}</name>
  <description></description>
  <remoteFS>{node_slave_home}</remoteFS>
  <numExecutors>{executors}</numExecutors>
  <mode>NORMAL</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy$Always"/>
  <launcher class="hudson.plugins.sshslaves.SSHLauncher" plugin="ssh-slaves@1.9">
    <host>{node_name}</host>
    <port>{ssh_port}</port>
    <credentialsId>{cred_id}</credentialsId>
  </launcher>
  <label>{labels}</label>
  <nodeProperties/>
  <userId>{user_id}</userId>
</slave>"""


def created(name, credential, remote_fs='', ssh_port=22, **kwargs):
    _runcli = __salt__['jenkins.runcli']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    new = _create_xml_template.format(
        node_name=name,
        node_slave_home=remote_fs,
        executors=2,
        ssh_port=ssh_port,
        cred_id=credential,
        user_id='',
        labels='')

    try:
        current = _runcli('get-node', name)
    except Exception:
        current = ''
        command = 'create-node'
    else:
        command = 'update-node'

    if new == current:
        ret['result'] = True
        ret['comment'] = "Node is created and config is up to date"
        return ret

    if not __opts__['test']:  # noqa
        try:
            _runcli(command, name, input_=new)
        except Exception, e:
            ret['comment'] = e.message
            return ret

    diff = '\n'.join(difflib.unified_diff(
        current.splitlines(), new.splitlines()))
    ret['comment'] = 'Changed'
    ret['changes'][name] = {
        'diff': diff,
    }
    ret['result'] = True
    return ret


def absent(name):
    _runcli = __salt__['jenkins.runcli']  # noqa
    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    try:
        _runcli('delete-node', name)
    except Exception, e:
        if "No such slave" in e.message:
            ret['comment'] = "Already removed"
        else:
            ret['comment'] = e.message
            return ret
    else:
        ret['changes'][name] = {
            'old': 'present',
            'new': 'absent',
        }

    ret['result'] = True
    return ret
