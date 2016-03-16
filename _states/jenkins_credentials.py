import logging

create_credential_groovy = u"""\
import jenkins.*;
import jenkins.model.*;
import hudson.*;
import hudson.model.*;

import com.cloudbees.plugins.credentials.domains.Domain;
import com.cloudbees.plugins.credentials.CredentialsScope;

domain = Domain.global()
store = Jenkins.instance.getExtensionList(
  'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
)[0].getStore()

credentials_new = new {cls}(
  CredentialsScope.GLOBAL, "{name}",
  {args}
)

creds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
      {cls}.class, Jenkins.instance
);
updated = false;

for (credentials_current in creds) {{
  // Comparison does not compare passwords but identity.
  if (credentials_new == credentials_current) {{
    store.removeCredentials(domain, credentials_current);
    ret = store.addCredentials(domain, credentials_new)
    updated = true;
    println("OVERWRITTEN");
    break;
  }}
}}

if (!updated) {{
  ret = store.addCredentials(domain, credentials_new)
  if (ret) {{
    println("CREATED");
  }} else {{
    println("FAILED");
  }}
}}
"""  # noqa


logger = logging.getLogger(__name__)


def render_create_credentials_script(cls, name, args):
    return create_credential_groovy.format(
        cls=cls, name=name, args=', '.join(args),
    )


def present(name, cls, args, **kwargs):
    _runcli = __salt__['jenkins.runcli']  # noqa
    test = __opts__['test']  # noqa

    ret = {
        'name': name,
        'changes': {},
        'result': False,
        'comment': '',
    }

    groovy = render_create_credentials_script(cls, name, args)
    try:
        logger.debug(u"Execute groovy script \n%s", groovy)
        if test:
            status = 'CREATED'
        else:
            status = _runcli('groovy', '=', input_=groovy).strip()
            assert 'FAILED' != status, "Groovy failed"
    except Exception, e:
        logger.error("Groovy script execution failure: %s", e)
        ret['comment'] = 'Failed: %s' % (e,)
        return ret

    ret['result'] = None if test else True
    ret['comment'] = 'Credentials ' + status.lower()
    if status in ('CREATED', 'OVERWRITTEN'):
        ret['changes'][name] = status

    return ret
