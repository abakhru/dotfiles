#!/usr/bin/env bash

echo "Create the admin account"
mongo admin --eval "db.createUser({user: 'admin', pwd: 'netwitness', roles: ['readWriteAnyDatabase', 'userAdminAnyDatabase', 'dbAdminAnyDatabase']})"

echo "Create the ESA MongoDB storage service account"
mongo admin -u admin -p netwitness --eval "db.getSiblingDB('esa').createUser({user: 'esa', pwd:'esa', roles: ['readWrite', 'dbAdmin']})"

echo "Create ESA MongoDB storage query(read-only) account"
mongo admin -u admin -p netwitness --eval "db.getSiblingDB('esa').createUser({user: 'esa_query', pwd:'esa', roles: ['read']})"

echo "If everything went well, the command below will NOT return any output."
mongo --quiet esa --eval "db.getCollectionNames()" -u esa -p esa | grep -q system.indexes,system.users

echo "Allow ds db access for esa user\n"
mongo admin -u admin -p netwitness --eval "db.getSiblingDB('ds').createUser({user: 'esa', pwd:'esa', roles: ['readWrite', 'dbAdmin']})"

echo "Creating Context-hub MongoDB storage service account\n"
# mongo admin -u admin -p netwitness --eval "db.getSiblingDB('context-wds').dropDatabase()"
mongo admin -u admin -p netwitness --eval "db.getSiblingDB('context-wds').createUser({user: 'context', pwd:'context', roles: ['readWrite', 'dbAdmin']})"

echo "Create the IM MongoDB storage service account"
mongo admin -u admin -p netwitness --eval "db.getSiblingDB('im').createUser({user: 'im', pwd:'im', roles: ['readWrite', 'dbAdmin']})"
