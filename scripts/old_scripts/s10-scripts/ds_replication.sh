#Replication will be between two nodes
# Say Node1 is (bakhru.red.iplanet.com:389) and node2 is (bakhru.red.iplanet.com:1389)
# Node2 will have all the replication data from Node1

# dsconf options that are used:
# -w :  Binds with password read from FILE (Default:$LDAP_ADMIN_PWF or prompt for password)
# -c :  Does not ask for confirmation before accepting non-trusted server certificates
echo netscape > /tmp/.passwd
cd /opt/sun/dsee7/bin

# Create another instance on same host for MMR setup
./dsadm create -D"cn=directory manager" -p 1389 -P 1636 -w /tmp/.passwd /var/opt/sun/ds7/dsins2

# On Node1 execute the following:
#STEP I
./dsconf enable-repl -c -w /tmp/.passwd -h bakhru.red.iplanet.com -p 389 -d 1 master o=usergroup
./dsconf enable-repl -c -w /tmp/.passwd -h bakhru.red.iplanet.com -p 1389 -d 1 master o=usergroup

#STEP II
./dsconf create-repl-agmt -c -w /tmp/.passwd -h bakhru.red.iplanet.com -p 389 o=usergroup bakhru.red.iplanet.com:1389
./dsconf create-repl-agmt -c -w /tmp/.passwd -h bakhru.red.iplanet.com -p 1389 o=usergroup bakhru.red.iplanet.com:389

#STEP III
./dsconf init-repl-dest -c -w /tmp/.passwd -h bakhru.red.iplanet.com -p 389 o=usergroup bakhru.red.iplanet.com:1389

# Repeat the above steps for o=comms-config, o=pab, o=PiServerDb and other suffixes

# To check replication status
./dsconf show-repl-agmt-status -c -w /tmp/.passwd o=usergroup bakhru.red.iplanet.com:389

# To configure ldap failover for full ms, configure the following:
configutil -o local.ugldaphost -v "bakhru.red.iplanet.com rvassar.central.sun.com:389"

# To configure ldap failover for MMP, configure the following in all *AService.cfg files:
default:LdapUrl "ldap://bakhru.red.iplanet.com/o=internet ldap://rvassar.central.sun.com/o=internet"
