# -*- coding: utf-8 -*-

import difflib
import xml.etree.ElementTree as ET

import salt.exceptions as exc


view_xml_tmpl = """
<hudson.model.ListView>
  <name>{name}</name>
  <filterExecutors>false</filterExecutors>
  <filterQueue>false</filterQueue>
  <properties class="hudson.model.View$PropertyList"/>
  <jobNames>
    <comparator class="hudson.util.CaseInsensitiveComparator"/>
  </jobNames>
  <jobFilters />
  <columns>
  </columns>
  <recurse>false</recurse>
</hudson.model.ListView>
"""  # noqa


def present(name, columns=None):
    """Ensures jenkins view is present.

    name
        The name of the view to be present.

    columns
        List of columns to add in the view.
    """

    runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': None if test else True,
        'comment': ''
    }

    # check exist and continue or create
    try:
        runcli('get-view', name)
        ret['comment'] = 'View `{0}` exists.'.format(name)
        return ret
    except exc.CommandExecutionError as e:
        pass

    # set columns
    view_xml = ET.fromstring(view_xml_tmpl.format(**{'name': name}))
    for c in columns or []:
        view_xml.find('columns').append(ET.Element(c))

    new = ET.tostring(view_xml.find('.'))

    # create
    if not test:
        try:
            runcli('create-view', name, input_=new)
        except exc.CommandExecutionError as e:
            ret['comment'] = e.message
            ret['result'] = False
            return ret

    ret['changes'] = {
        'old': None,
        'new': new,
    }
    return ret


def absent(name):
    """Ensures jenkins view is absent.

    name
        The name of the view to be present.
    """

    runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': None if test else True,
        'comment': ''
    }

    # check exist
    try:
        old = runcli('get-view', name)
    except exc.CommandExecutionError as e:
        ret['comment'] = 'View `{0}` not found'.format(name)
        return ret

    # delete
    if not test:
        try:
            runcli('delete-view', name)
        except exc.CommandExecutionError as e:
            ret['comment'] = e.message
            ret['result'] = False
            return ret

    ret['changes'] = {
        'old': old,
        'new': None,
    }

    return ret


def get_view_jobs(view_str):
    return [e.text for e in ET.fromstring(view_str).find('jobNames').findall('string')]  # noqa


def job_present(name, job=None, jobs=None):
    """Ensure jenkins job is present in a given view.

    name
        The view.

    job
        The job to add to the view.

    jobs
        List of jobs name to add at once.
    """

    runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': ''
    }

    if not jobs and not job:
        ret['comment'] = "Missing job name"
        return ret

    if not jobs:
        jobs = [job]

    # check exist
    try:
        old = runcli('get-view', name)
    except exc.CommandExecutionError as e:
        ret['comment'] = e.message
        return ret

    jobs = set(jobs + get_view_jobs(old))

    # parse, clean and update xml
    view_xml = ET.fromstring(old)
    root = view_xml.find('jobNames')
    root.clear()
    # Indentation
    root.text = "\n    "
    root.tail = "\n  "

    for i, job in enumerate(sorted(jobs)):
        job_xml = ET.Element('string')
        job_xml.text = job
        next_indent_level = 2 if i in range(len(jobs) - 1) else 1
        job_xml.tail = "\n" + next_indent_level * "  "
        view_xml.find('jobNames').append(job_xml)

    new = """<?xml version="1.0" encoding="UTF-8"?>\n"""
    new += ET.tostring(view_xml.find('.'))
    # Follow jenkins-cli convention
    new = new.replace(" />", "/>")

    if old == new:
        ret['comment'] = 'No changes'
        ret['result'] = True
    else:
        diff = '\n'.join(difflib.unified_diff(
            old.splitlines(), new.splitlines()))

        ret['changes'] = {
            'diff': diff,
        }

        # update if not testing
        if test:
            ret['result'] = None
        else:
            try:
                _runcli('update-view', name, input_=new)
            except exc.CommandExecutionError as e:
                ret['comment'] = e.message
                return ret
            ret['result'] = True

    return ret
