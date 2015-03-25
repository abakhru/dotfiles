import time
import requests
import pexpect
import urllib
import os, getopt
import sys
from HTMLParser import HTMLParser
import urllib3
requests.packages.urllib3.disable_warnings()

os.system("unset no_proxy NO_PROXY http_proxy HTTP_PROXY https_proxy HTTPS_PROXY npm_config_proxy npm_config_https_proxy")

global username, password
username = "root"
password = "netwitness"

class RealeaseFeedParser(HTMLParser):
  """
  HTMLParser class to parse the html of the release urls
  """
  data = []
  esa_client = []
  esa_server = []
  sa_server = []

  def handle_data(self, data):
    """
    Overrides the HTMLParser method to do some extra processing.
    Extra processing:
      1) Store a list of all rpms
      2) Store a list of esa_client rpms
      3) Store a list of esa_server rpms
      4) Store a list of sa_server rpms
    """
    if ".rpm" in data:
      self.data.append(data)

      if "security-analytics-web-server" in data:
        self.sa_server.append(data)

      if "rsa-esa-client" in data:
        self.esa_client.append(data)

      if "rsa-esa-server" in data:
        self.esa_server.append(data)

class PexpectHandler(object):
  """ Pexpect class to handle commands that need to be run on a remote machine.
  """

  def __init__(self, vm_ip, prompt="root@.* ~]#", user=username, password=password):
    """ Called automatically when class is instantiated

    Args:
      vm_ip: Resolvable Hostname or simply the ip of the remote machine (str)
      prompt: Expected prompt of the remote machine (str)
      user: Username to log in to that remote machine (str)
      password: Password to log in to that remote machine (str)
    """
    self._vm_ip = vm_ip
    self._prompt = prompt
    self._user = user
    self._password = password
    self._newkey = 'Are you sure you want to continue connecting'

    self._child = pexpect.spawn("ssh %s@%s" %(self._user, self._vm_ip))
    self.authenticateUser()

  def authenticateUser(self):
    """ Method to authenticate the user.
    Multiple scenarios will be handled:
      1) SSHing for the first time and hence asking to connect anyway.
      2) SSHed before (machine is a known host), and simply entering the password
      3) Access Denied
      4) SSH bridge has been setup previously and directly logs the user in
    """

    i = self._child.expect([self._newkey,'password:', pexpect.EOF, self._prompt], timeout=10)

    if i==0:
        self._child.sendline('yes')
        self.authenticateUser()
    if i==1:
        self._child.sendline(self._password)
        self.authenticateUser()
    if i==2:
        print "Connection failed!"
        pass
    elif i==3:
        pass

  def runCommand(self, command, response=None, timeout=30):
    """ Runs a command on the the remote machine

    Args:
      command: The literal command that needs to be executed (str)
      response: Message to be seen after running the above command (str)
      timeout: The time in seconds the command takes to be executed (int)
    """
    if response==None:
      response=self._prompt

    self._child.sendline(command)
    self._child.expect(response, timeout=timeout)

  def getLastLineOfOutput(self):
    """ Return the last line of the output of the previous command
    """

    return self._child.before.split('\r\n')[1]

  def getFullOuput(self):
    """ Returns the full output of the previously run command as a list
    """

    return self._child.before.split('\r\n')

  def close(self):
    """ Closes the SSH connection
    """

    self._child.close()


def main():

  def close_ssh_connections():
    """ Closes the open SSH connections
    """
    try:
      print "\nClosing ssh connections ..."
      esa_vm.close()
      sa_vm.close()
      parser.close()
    except Exception, err:
      print Exception("Unable to close ssh connections.\n%s" %err)

  def sa_cleanup():
    """ Cleans up any mess because of the SA upgrade steps.
    """

    try:
      print "\nDeleting the local sa rpm copy ..."
      os.remove(sa_server_rpm)
    except Exception, err:
      print "Unable to delete local sa rpm."
      print Exception("Delete manually.\n%s" %err)
    try:
      print "Deleting the scp-ed sa rpm file ..."
      sa_vm.runCommand("rm -rf %s" %sa_server_rpm)
    except Exception, err:
      print "Unable to delete remotely copied sa rpm."
      print Exception("Delete manually.\n%s" %err)

  def esa_cleanup():
    """ Cleans up any mess because of the ESA upgrade steps.
    """

    try:
      print "\nDeleting the downloaded esa rpm files ..."
      esa_vm.runCommand("rm -rf %s %s" %(esa_server_rpm, esa_client_rpm))
    except Exception, err:
      print "Unable to delete the downloaded esa rpm files."
      print Exception("Delete manually.\n%s" %err)

  # Default sa and esa VM hosts
  sa_ip = ""
  esa_ip = ""

  # Handle options passed to the script
  try:
    opts, args = getopt.getopt(sys.argv[1:],"hs:e:",["sa-vm-ip=","esa-vm-ip="])
  except getopt.GetoptError:
    print 'upgrade.py -s <sa vm> -e <esa vm>'
    raise Exception('Missing options.')
  for opt, arg in opts:
    if opt == '-h':
      print 'upgrade.py -s <sa vm> -e <esa vm>'
      sys.exit()
    elif opt in ("-s", "--sa-vm-ip"):
      sa_ip = arg
    elif opt in ("-e", "--esa-vm-ip"):
      esa_ip = arg

  # URLs of the Release Enginnering Lab
  release_lab1_url = 'http://devrepo.netwitness.local/RSA/10.5/10.5.0/10.5.0.0/'
  release_lab2_url = 'https://libhq-ro.rsa.lab.emc.com/SA/YUM/RSA/10.5/10.5.0/10.5.0.0/'

  # Creates a requests and HTMLParser object
  session = requests.session()
  parser = RealeaseFeedParser()

  try:
    try:
      print "Checking ssh connection to %s and %s" %(sa_ip, esa_ip)
      esa_vm = PexpectHandler(esa_ip)
      sa_vm = PexpectHandler(sa_ip)
      print "Ssh connection established."
    except Exception, e:
      print "Unable to ssh ... exiting ..."
      raise Exception("\n%s" %e)

    print "\nObtaining latest rpms ..."
    rpms = session.get(release_lab1_url, verify=False)
    esa_rpms = session.get(release_lab2_url, verify=False)

    parser.feed(rpms.text)
    parser.feed(esa_rpms.text)

    sa_server_rpm = max(parser.sa_server)
    esa_server_rpm = max(parser.esa_server)
    esa_client_rpm = max(parser.esa_client)

    sa_server_rpm_path = release_lab1_url + sa_server_rpm
    esa_server_rpm_path = release_lab2_url + esa_server_rpm
    esa_client_rpm_path = release_lab2_url + esa_client_rpm
    print "Latest rpms have been obtained."
    print "\t(1) sa: %s" %(sa_server_rpm)
    print "\t(2) esa-server: %s" %(esa_server_rpm)
    print "\t(3) esa-client: %s" %(esa_client_rpm)


    try:
      print "\nDownloading sa rpm locally ..."
      urllib.urlretrieve (sa_server_rpm_path, sa_server_rpm)
      print "\nCopying the sa rpm to %s ..." %sa_ip
      child = pexpect.spawn("scp %s %s@%s:/%s/" %(sa_server_rpm, username, sa_ip, username))
      child.expect("password:")
      child.sendline("%s" %password)
      child.expect(pexpect.EOF, timeout=300)
    except Exception, e:
      print "Unable to save and copy sa rpm."
      sa_cleanup()
      raise Exception("\n%s" %e)

    try:
      print "\nStopping the sa service"
      sa_vm.runCommand("stop jettysrv")
      sa_vm.runCommand("rpm -qa | grep security-analytics-web-server")
      old_sa_server = sa_vm.getLastLineOfOutput()
      if old_sa_server:
        print "\nRemoving old sa server - \"%s\"" %old_sa_server
        sa_vm.runCommand("rpm -e %s" %old_sa_server)
        print "Old sa server has been removed."
      else:
        print "\nNo sa server installed, nothing to remove."

      print "\nInstalling the new rpm ..."
      sa_vm.runCommand("rpm -i %s" %sa_server_rpm)
      print "New rpm have been installed."

      print "\nStarting the sa server ..."
      sa_vm.runCommand("start jettysrv")
      print "Sa server has been started."

      print "\nWaiting for success message in logs (may take a while) ..."
      sa_vm.runCommand('tail -f /var/lib/netwitness/uax/logs/sa.log'
                        , response=".*Successfully added appliance stats for host SA.*"
                        , timeout= 300)
      print "\nSuccess message seen."

      sa_vm.runCommand('\003')

    except Exception, e:
      print "Unable to update sa server."
      sa_cleanup()
      raise Exception("\n%s" %e)

    sa_cleanup()

    try:
      print "\nDownloading the new esa rpms to %s..." %esa_ip
      esa_vm.runCommand("wget --no-check-certificate %s" %esa_server_rpm_path)
      esa_vm.runCommand("wget --no-check-certificate %s" %esa_client_rpm_path)
    except Exception, e:
      print "Unable to download new esa rpms."
      esa_cleanup()
      raise Exception("\n%s" %e)

    try:
      print "\nStopping the esa service"
      esa_vm.runCommand("service rsa-esa stop")

      esa_vm.runCommand("rpm -qa | grep esa-server")
      old_esa_server = esa_vm.getLastLineOfOutput()
      print "\nRemoving old esa server - \"%s\"" %old_esa_server
      esa_vm.runCommand("rpm -e %s" %old_esa_server)
      print "Old esa server has been removed."

      esa_vm.runCommand("rpm -qa | grep esa-client")
      old_esa_client = esa_vm.getLastLineOfOutput()
      print "\nRemoving old esa client - \"%s\"" %old_esa_client
      esa_vm.runCommand("rpm -e %s" %old_esa_client)
      print "Old esa client has been removed."

      print "\nInstalling the new esa rpms ..."
      esa_vm.runCommand("rpm -i %s; rpm -i %s" %(esa_server_rpm, esa_client_rpm))
      print "New esa rpms have been installed."

      print "\nStarting the esa service ..."
      esa_vm.runCommand("service rsa-esa start")
      print "Esa service has been started."
    except Exception, e:
      print "Unable to update esa server."
      esa_cleanup()
      raise Exception("\n%s" %e)

    esa_cleanup()

  except Exception, error:
    close_ssh_connections()
    raise Exception("\n\n%s" %error)

  close_ssh_connections()
  print "\nUpgrade Complete!"

if  __name__ =='__main__':
  main()