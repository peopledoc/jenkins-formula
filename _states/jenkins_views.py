# -*- coding: utf-8 -*-
import xml.etree.ElementTree as ET

import salt.exceptions as exc


view_xml_tmpl = """
<hudson.model.ListView>
  <name>{name}</name>
  <filterExecutors>false</filterExecutors>
  <filterQueue>false</filterQueue>
  <properties class="hudson.model.View$PropertyList" />
  <jobNames>
    <comparator class="hudson.util.CaseInsensitiveComparator" />
    {jobs}
  </jobNames>
  <jobFilters />
  <columns>
    <hudson.views.JobColumn />
    <hudson.views.WeatherColumn />
    <hudson.views.StatusColumn />
    <org.jenkinsci.plugins.github__commit__hook.GithubCommitHookLastMasterStatus plugin="github-commit-hook@1.7">
      <length>20</length>
    </org.jenkinsci.plugins.github__commit__hook.GithubCommitHookLastMasterStatus>
    <hudson.views.LastSuccessColumn />
    <hudson.views.LastFailureColumn />
    <hudson.views.LastDurationColumn />
    <jenkins.plugins.extracolumns.LastBuildConsoleColumn plugin="extra-columns@1.15" />
    <hudson.views.BuildButtonColumn />
  </columns>
  <recurse>false</recurse>
</hudson.model.ListView>
"""  # noqa


def get_view_jobs(view_str):
    return [e.text for e in ET.fromstring(view_str).find('jobNames').findall('string')]  # noqa


def present(name, names=None, **kwargs):
    """Ensure jenkins views are present.

    name
        The name of one specific view to be present.

    names
        The names of specifics views to be present.
    """

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    if not names:
        names = [name]

    _runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa
    for view in names:

        # check exist
        try:
            old = _runcli('get-view', view)
            jobs = get_view_jobs(old)
            command = 'update-view'
        except exc.CommandExecutionError as e:
            old = None
            jobs = []
            command = 'create-view'

        new = view_xml_tmpl.format(**{
            'name': view,
            'jobs': '\n'.join(['<string>{0}</string>'.format(j) for j in jobs])
        })

        # update
        if not test:
            try:
                _runcli(command, view, input_=new)
            except exc.CommandExecutionError as e:
                ret['comment'] = e.message
                return ret
        else:
            pass

        # fresh install
        ret['changes'][view] = {
            'old': old,
            'new': new,
        }

    ret['result'] = None if test else True
    return ret


def job_present(name, names=None, view=None, **kwargs):
    """Ensure jenkins jobs are present in a given view.

    name
        The name of one specific job to be present.

    names
        The names of specifics jobs to be present.

    view
        The target view.
    """

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    if not names:
        names = [name]

    if not view:
        ret['comment'] = 'Missing view.'
        return ret

    _runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    # check exist
    try:
        old = _runcli('get-view', view)
        names += get_view_jobs(old)
        command = 'update-view'
    except exc.CommandExecutionError as e:
        old = None
        command = 'create-view'

    new = view_xml_tmpl.format(**{
        'name': view,
        'jobs': '\n'.join(['<string>{0}</string>'.format(j)
                           for j in sorted(set(names))])
    })

    # update
    if not test:
        try:
            _runcli(command, view, input_=new)
        except exc.CommandExecutionError as e:
            ret['comment'] = e.message
            return ret
    else:
        pass

    # fresh install
    ret['changes'][view] = {
        'old': old,
        'new': new,
    }

    ret['result'] = None if test else True
    return ret


def absent(name, names=None):

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    if not names:
        names = [name]

    _runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa
    for view in names:

        # check exist
        try:
            old = _runcli('get-view', view)
        except exc.CommandExecutionError as e:
            continue

        # update
        if not test:
            try:
                _runcli('delete-view', view)
            except exc.CommandExecutionError as e:
                ret['comment'] = e.message
                return ret
        else:
            pass

        ret['changes'][view] = {
            'old': old,
            'new': None,
        }

    ret['result'] = None if test else True
    return ret


def job_absent(name, names=None, view=None, **kwargs):
    """Ensure jenkins jobs are absent in a given view.

    name
        The name of one specific job to be absent.

    names
        The names of specifics jobs to be absent.

    view
        The target view.
    """

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    if not names:
        names = [name]

    if not view:
        ret['comment'] = 'Missing view.'
        return ret

    _runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    # check exist
    try:
        old = _runcli('get-view', view)
        previous_jobs = get_view_jobs(old)
        command = 'update-view'
    except exc.CommandExecutionError as e:
        ret['comment'] = e.message
        return ret

    new = view_xml_tmpl.format(**{
        'name': view,
        'jobs': '\n'.join(['<string>{0}</string>'.format(j)
                           for j in sorted(set(previous_jobs))
                           if j not in names])
    })

    # update
    if not test:
        try:
            _runcli(command, view, input_=new)
        except exc.CommandExecutionError as e:
            ret['comment'] = e.message
            return ret
    else:
        pass

    # fresh install
    ret['changes'][view] = {
        'old': old,
        'new': new,
    }

    ret['result'] = None if test else True
    return ret
