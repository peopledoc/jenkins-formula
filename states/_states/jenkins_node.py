# -*- coding: utf-8 -*-
import subprocess


def _cli(*args, **kwargs):
    args = ('/usr/local/bin/jenkins-cli',) + args

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
    return p.returncode, p.stdout.read(), p.stderr.read()


_create_xml_template = """\
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
</slave>
"""


def created(name, credential, remote_fs='', ssh_port=22, **kwargs):
    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    data = _create_xml_template.format(
        node_name=name,
        node_slave_home=remote_fs,
        executors=2,
        ssh_port=ssh_port,
        cred_id=credential,
        user_id='',
        labels='')

    retcode, stdout, stderr = _cli('get-node', name)
    if retcode == 0:
        current = stdout
        if data == current:
            ret['result'] = True
            ret['comment'] = "Node is created and config up to date"
            return ret
        else:
            command = 'update-node'
    else:
        current = ''
        command = 'create-node'

    retcode, stdout, stderr = _cli(command, name, input_=data)
    if retcode != 0:
        ret['comment'] = stderr
        return ret

    ret['changes'][name] = {
        'old': current,
        'new': data,
    }
    ret['result'] = True
    return ret


def absent(name):
    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    retcode, stdout, stderr = _cli('delete-node', name)
    if retcode != 0:
        if "No such slave" in stderr:
            ret['comment'] = "Already removed"
        else:
            ret['comment'] = stderr
            return ret
    else:
        ret['changes'][name] = {
            'old': 'present',
            'new': 'absent',
        }

    ret['result'] = True
    return ret
