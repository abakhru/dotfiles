#!/usr/bin/env python

import logging

from cassandra import ConsistencyLevel
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement

KEYSPACE = 'perm'

def main():

    cluster = Cluster(['127.0.0.1'])
    session = cluster.connect()
    rows = session.execute("SELECT keyspace_name FROM system.schema_keyspaces")
    for row in rows:
            if row[0] is 'perm_testcqldb_1394578855_billyjack_27557':
                    continue
            if row[0].startswith(KEYSPACE):
                print "dropping existing keyspace...%s" % row
                session.execute("DROP KEYSPACE " + row[0])

if __name__ == "__main__":
    main()
