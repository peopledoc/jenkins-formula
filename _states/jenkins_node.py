# -*- coding: utf-8 -*-
import difflib

import xml.etree.ElementTree as ET

import salt.exceptions as exc


_create_xml_template = """\
<?xml version="1.0" encoding="UTF-8"?>
<slave>
  <name>{node_name}</name>
  <description></description>
  <remoteFS>{node_slave_home}</remoteFS>
  <numExecutors>{executors}</numExecutors>
  <mode>NORMAL</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy$Demand">
    <inDemandDelay>0</inDemandDelay>
    <idleDelay>1440</idleDelay>
  </retentionStrategy>
  <launcher class="hudson.plugins.sshslaves.SSHLauncher" plugin="ssh-slaves@1.10">
    <host>{host}</host>
    <port>{ssh_port}</port>
    <credentialsId>{cred_id}</credentialsId>
    <launchTimeoutSeconds>10</launchTimeoutSeconds>
    <maxNumRetries>0</maxNumRetries>
    <retryWaitTime>5</retryWaitTime>
  </launcher>
  <label>{labels}</label>
  <nodeProperties/>
  <userId>{user_id}</userId>
</slave>"""  # noqa


def present(name, credential, host=None, labels=None, num_executors=None,
            remote_fs='', ssh_port=22):

    runcli = __salt__['jenkins.runcli']  # noqa
    ncpus = __grains__['num_cpus']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    new = _create_xml_template.format(
        node_name=name,
        host=host or name,
        node_slave_home=remote_fs,
        executors=num_executors or ncpus,
        ssh_port=ssh_port,
        cred_id=credential,
        user_id='anonymous',
        labels=' '.join(labels or []))

    try:
        current = runcli('get-node', name)
    except Exception:
        current = ''
        command = 'create-node'
    else:
        command = 'update-node'

    if new == current:
        ret['result'] = True
        ret['comment'] = 'Node not changed.'
        return ret

    if not __opts__['test']:  # noqa
        try:
            ret['comment'] = runcli(command, name, input_=new)
        except Exception, e:
            ret['comment'] = e.message
            return ret
        else:
            ret['result'] = True
    else:
        ret['result'] = None

    diff = '\n'.join(difflib.unified_diff(
        current.splitlines(), new.splitlines()))

    ret['comment'] = 'Changed'
    ret['changes'] = {
        'diff': diff,
    }
    return ret


def connected(name):
    runcli = __salt__['jenkins.runcli']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    if not __opts__['test']:  # noqa
        try:
            ret['comment'] = runcli('connect-node', name)
            ret['changes'] = {
                'connected': True,
            }
        except Exception, e:
            ret['comment'] = e.message
            return ret
        else:
            ret['result'] = True
    else:
        ret['result'] = None

    return ret


def absent(name):
    runcli = __salt__['jenkins.runcli']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    try:
        runcli('get-node', name)
    except Exception:
        ret['comment'] = 'Already removed'
        ret['result'] = True
        return ret

    if not __opts__['test']:  # noqa
        try:
            ret['comment'] = runcli('delete-node', name)
        except Exception, e:
            ret['comment'] = e.message
            return ret
        else:
            ret['result'] = True
    else:
        ret['result'] = None

    ret['changes'] = {
        'old': 'present',
        'new': 'absent',
    }
    return ret


def label_present(name, label):
    """Ensure jenkins label is present in a given node.

    name
        The target node.

    label
        The name of the label to be present.
    """

    runcli = __salt__['jenkins.runcli']  # noqa
    update_or_create_xml = __salt__['jenkins.update_or_create_xml']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    # check exist
    try:
        old = runcli('get-node', name)
    except exc.CommandExecutionError as e:
        ret['comment'] = e.message
        return ret

    # parse node xml
    node_xml = ET.fromstring(old)

    # get merge with previous labels
    labels = [label] + (node_xml.find('label').text or '').split(' ')

    # parse, clean and update xml
    node_xml.find('label').text = ' '.join(sorted(set(labels)))

    return update_or_create_xml(name, node_xml, old, object_='node')


def label_absent(name, label):
    """Ensure jenkins label is absent in a given node.

    name
        The target node.

    label
        The name of the label to be absent.
    """

    runcli = __salt__['jenkins.runcli']  # noqa
    update_or_create_xml = __salt__['jenkins.update_or_create_xml']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    # check exist
    try:
        old = runcli('get-node', name)
    except exc.CommandExecutionError as e:
        ret['comment'] = e.message
        return ret

    # parse node xml
    node_xml = ET.fromstring(old)

    # get previous labels except the one that should be absent
    labels = [l for l in (node_xml.find('label').text or '').split(' ')
              if l != label]

    # parse, clean and update xml
    node_xml.find('label').text = ' '.join(sorted(set(labels)))

    return update_or_create_xml(name, node_xml, old, object_='node')
