#!/usr/bin/env python

from cassandra import ConsistencyLevel
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement

KEYSPACE = "testkeyspace"


def main():
    cluster = Cluster(['127.0.0.1'])
    session = cluster.connect()
    rows = session.execute("SELECT keyspace_name FROM system.schema_keyspaces")
    if KEYSPACE in [row[0] for row in rows]:
        print("dropping existing keyspace...")
        session.execute("DROP KEYSPACE " + KEYSPACE)

    print("creating keyspace...")
    session.execute("""
        CREATE KEYSPACE %s
        WITH replication = { 'class': 'SimpleStrategy', 'replication_factor': '1' }
        """ % KEYSPACE)

    print("setting keyspace...")
    session.set_keyspace(KEYSPACE)

    print("creating table...")
    session.execute("""
        CREATE TABLE mytable (
            thekey text,
            col1 text,
            col2 text,
            PRIMARY KEY (thekey, col1)
        )
        """)

    query = SimpleStatement("""
        INSERT INTO mytable (thekey, col1, col2)
        VALUES (%(key)s, %(a)s, %(b)s)
        """, consistency_level=ConsistencyLevel.ONE)

    prepared = session.prepare("""
        INSERT INTO mytable (thekey, col1, col2)
        VALUES (?, ?, ?)
        """)

    for i in range(10):
        print("inserting row %d" % i)
        session.execute(query, dict(key="key%d" % i, a='a', b='b'))
        session.execute(prepared.bind(("key%d" % i, 'b', 'b')))

    future = session.execute_async("SELECT * FROM mytable")
    # print("key\tcol1\tcol2")
    # print("---\t----\t----")

    try:
        rows = future.result()
    except Exception:
        log.exeception()

    # for row in rows:
    #    print('\t'.join(row))

    session.execute("DROP KEYSPACE " + KEYSPACE)
    session.shutdown()
    cluster.shutdown()


if __name__ == "__main__":
    for i in range(0, 1000):
        print("==== loop %d" % i)
        main()
