# -*- coding: utf-8 -*-
import os
import xml.etree.ElementTree as ET

import salt.exceptions as exc


default = """\
<?xml version='1.0' encoding='UTF-8'?>
<hudson>
  <disabledAdministrativeMonitors/>
  <numExecutors>0</numExecutors>
  <mode>NORMAL</mode>
  <useSecurity>true</useSecurity>
  <authorizationStrategy class="hudson.security.AuthorizationStrategy$Unsecured"/>
  <securityRealm class="hudson.security.SecurityRealm$None"/>
  <disableRememberMe>false</disableRememberMe>
  <projectNamingStrategy class="jenkins.model.ProjectNamingStrategy$DefaultProjectNamingStrategy"/>
  <workspaceDir>${JENKINS_HOME}/workspace/${ITEM_FULLNAME}</workspaceDir>
  <buildsDir>${ITEM_ROOTDIR}/builds</buildsDir>
  <jdks/>
  <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
  <myViewsTabBar class="hudson.views.DefaultMyViewsTabBar"/>
  <clouds/>
  <slaves/>
  <quietPeriod>5</quietPeriod>
  <scmCheckoutRetryCount>0</scmCheckoutRetryCount>
  <views>
    <hudson.model.AllView>
      <owner class="hudson" reference="../../.."/>
      <name>All</name>
      <filterExecutors>false</filterExecutors>
      <filterQueue>false</filterQueue>
      <properties class="hudson.model.View$PropertyList"/>
    </hudson.model.AllView>
  </views>
  <primaryView>All</primaryView>
  <slaveAgentPort>0</slaveAgentPort>
  <label></label>
  <nodeProperties/>
  <globalNodeProperties/>
</hudson>
"""  # noqa


def managed(name, text='', create=False, **kwargs):
    """Manages jenkins config content for a given xpath.

    name
        The xpath to be managed.

    text
        The content to set at the given xpath.

    create
        Creates element for the given xpath if not exist (NOT IMPLEMENTED).
    """

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    formatdiff = __salt__['jenkins.formatdiff']  # noqa
    # load config
    home = __pillar__['jenkins'].get('home', '/var/lib/jenkins')  # noqa
    test = __opts__['test']  # noqa

    config_path = os.path.join(home, 'config.xml')

    if not os.path.exists(config_path):
        if test:
            ret['comment'] = 'New config would have been written'
            ret['result'] = None
            return ret
        else:
            open(config_path, 'w').write(default)

    config = ET.parse(config_path)

    # check exist
    if config.find(name) is None and not create:
        ret['comment'] = '`{0}` not found.'.format(name)
        return ret

    old = ET.tostring(config.find('.'))
    config.find(name).text = str(text)
    diff = formatdiff(old, new=ET.tostring(config.find('.')))
    if diff:
        ret['changes']['diff'] = diff

    if not test:
        config.write(config_path)

    ret['result'] = None if test else True
    return ret


def reloaded(name):

    ret = {
        'name': name,
        'changes': {
            'old': '',
            'new': 'done',
        },
        'result': False,
        'comment': ''
    }

    _runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    if not test:
        try:
            _runcli('reload-configuration')
        except exc.CommandExecutionError as e:
            ret['comment'] = e.message
            return ret
    else:
        pass

    ret['result'] = None if test else True
    return ret
