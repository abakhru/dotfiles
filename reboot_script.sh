#!/bin/sh -x

# start this script only during system reboot, once
# crontab -e
# @reboot ~/.ssh/reboot_script.sh
# script does the following:
# - starts a new ssh-agent
# - creates a forced soft-link of new ssh-agent to a common file
# tmuxinator then use the common-file as SSH_AUTH_SOCK env in all windows

rm -rf /tmp/ssh*
eval $(ssh-agent -s)
env | grep SSH
ln -sf ${SSH_AUTH_SOCK} ${HOME}/.ssh/ssh_auth_sock
