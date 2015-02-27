import os.path


def pub(user='root', key='id_rsa'):
    """Return public key for given user

    CLI Example:

        salt '*' ssh_key.pub
        salt '*' ssh_key.pub root id_rsa2

    """
    home = os.path.expanduser("~{0}".format(user))
    pub = '{0}.pub'.format(key)
    path = os.path.join(home, '.ssh', pub)
    with open(path) as f:
        return f.read()
