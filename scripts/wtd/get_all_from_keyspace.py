#!/usr/bin/env python

import sys

from cassandra import ConsistencyLevel
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement

KEYSPACE = str(sys.argv[1])

def main():

    cluster = Cluster(['127.0.0.1'])
    session = cluster.connect()

    print("setting keyspace...")
    session.set_keyspace(KEYSPACE)

    tables = session.execute("describe tables")
    print tables
    
    for table in tables:
        future = session.execute("SELECT * FROM table")
        print future

if __name__ == "__main__":
    main()
