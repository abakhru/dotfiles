#!/usr/bin/env python

hostname = 'mecha.silvertailsystems.com'
port = 2772
username = 'bakhra'
password = None
rsa_private_key = "~/.ssh/id_rsa"

import os
import glob
import hashlib
import paramiko

def agent_auth(transport, username):
    """
    Attempt to authenticate to the given transport using any of the private
    keys available from an SSH agent or from a local private RSA key file (assumes no pass phrase).
    """
    try:
        ki = paramiko.RSAKey.from_private_key_file(rsa_private_key)
    except Exception, e:
        print 'Failed loading' % (rsa_private_key, e)

    agent = paramiko.Agent()
    agent_keys = agent.get_keys() + (ki,)
    if len(agent_keys) == 0:
        return

    for key in agent_keys:
        print 'Trying ssh-agent key %s' % key.get_fingerprint().encode('hex'),
        try:
            transport.auth_publickey(username, key)
            print '... success!'
            return
        except paramiko.SSHException, e:
            print '... failed!', e

hostkeytype = None
hostkey = None
"""
try:
    host_keys = paramiko.util.load_host_keys(os.path.expanduser('~/.ssh/known_hosts'))
except IOError:
    try:
        host_keys = paramiko.util.load_host_keys(os.path.expanduser('~/ssh/known_hosts'))
    except IOError:
        print '*** Unable to open host keys file'
        host_keys = {}

if host_keys.has_key(hostname):
    hostkeytype = host_keys[hostname].keys()[0]
    hostkey = host_keys[hostname][hostkeytype]
    print 'Using host key of type %s' % hostkeytype
"""

# now, connect and use paramiko Transport to negotiate SSH2 across the connection
try:
    print 'Establishing SSH connection to:', hostname, port, '...'
    t = paramiko.Transport((hostname, port))
    t.start_client()

    agent_auth(t, username)

    if not t.is_authenticated():
        print 'RSA key auth failed! Trying password login...'
        t.connect(username=username, password=password, hostkey=hostkey)
    else:
        ssh = t.open_session()
#    ssh = paramiko.SSHClient.from_transport(t)

    t.close()

except Exception, e:
    print '*** Caught exception: %s: %s' % (e.__class__, e)
    try:
        t.close()
    except:
        pass

print 'All operations complete!'
