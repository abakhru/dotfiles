#!/bin/bash

echo "Start mongo db"
echo "mongod --config /usr/local/etc/mongod.conf"
mongod --config /usr/local/etc/mongod.conf

echo "Create the admin account"
echo "mongo admin --eval \"db.addUser({user: 'admin', pwd: 'netwitness', roles: ['readWriteAnyDatabase', 'userAdminAnyDatabase', 'dbAdminAnyDatabase']})\""
mongo admin --eval "db.addUser({user: 'admin', pwd: 'netwitness', roles: ['readWriteAnyDatabase', 'userAdminAnyDatabase', 'dbAdminAnyDatabase']})"

echo "Create the ESA MongoDB storage service account"
echo "mongo admin -u admin -p netwitness --eval \"db.getSiblingDB('esa').addUser({user: 'esa', pwd:'esa', roles: ['readWrite', 'dbAdmin']})\""
mongo admin -u admin -p netwitness --eval "db.getSiblingDB('esa').addUser({user: 'esa', pwd:'esa', roles: ['readWrite', 'dbAdmin']})"

echo "Create ESA MongoDB storage query(read-only) account"
echo "mongo admin -u admin -p netwitness --eval \"db.getSiblingDB('esa').addUser({user: 'esa_query', pwd:'esa', roles: ['read']})\""
mongo admin -u admin -p netwitness --eval "db.getSiblingDB('esa').addUser({user: 'esa_query', pwd:'esa', roles: ['read']})"

echo "If everything went well, the command below will NOT return any output."
echo "mongo --quiet esa --eval \"db.getCollectionNames()\" -u esa -p esa | grep -q system.indexes,system.users"
mongo --quiet esa --eval "db.getCollectionNames()" -u esa -p esa | grep -q system.indexes,system.users

echo "Now starting rabbitmq-server"
echo "/usr/local/bin/rabbitmq-server"
/usr/local/bin/rabbitmq-server
