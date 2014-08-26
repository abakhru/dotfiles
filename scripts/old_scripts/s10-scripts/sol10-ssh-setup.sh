#!/bin/sh

SSHD_DIR=/etc/ssh
export SSHD_DIR

if [ -f "$SSHD_DIR/ssh_host_key" ]
then
        :
else
        /usr/bin/ssh-keygen -trsa1 -b 1024 -f "$SSHD_DIR/ssh_host_key" -N ''
fi

if [ -f "$SSHD_DIR/ssh_host_dsa_key" ]
then
        :
else
        /usr/bin/ssh-keygen -d -f "$SSHD_DIR/ssh_host_dsa_key" -N ""
fi

if [ -f "$SSHD_DIR/ssh_host_rsa_key" ]
then
        :
else
        /usr/bin/ssh-keygen -t rsa -f "$SSHD_DIR/ssh_host_rsa_key" -N ""
fi

#sed '/RootLogin/ s/no/yes/' /etc/ssh/sshd_conf > /etc/ssh/sshd_conf.bk; mv /etc/ssh/sshd_conf.bk /etc/ssh/sshd_conf

svcadm enable svc:/network/ssh:default
svcadm disable ssh
svcadm enable ssh
ps -def|grep ssh

