#README.txt

WARNING: This is a work-in-progress and not final version.
This will eventually be integrated with STQA framework.

==============
TEST STRATEGY:
==============
The strategy of running performance test is to run it with specific number of
transactions with a certain pulish rate(as described below)


Safe Performance Setup details:
===============================
lab5 - cprofileupdater
lab6 - silvercat, silverplex-front, silversurfer, silverplex-back
lab9 - cassandra 

Normal runs (msgs/sec) & DELAY value:
====================================
1000 : 1000 (microseconds)
2000 : 500 (microseconds)
4000 : 250 (microseconds)
8000 : 125 (microseconds)
16000 : 62 (microseconds)

NOTE: To double the publishing rate, reduce the delay by half

Execution Steps:
================
- run redoit.sh
(This will restart all the servers on lab5, lab6 and lab9 machines)
- copy the new unique keyspace name
- launch https://lab6/silvercat 
- edit CassandraClient configuration in silvercat, paste the new keyspace in keyspace section
- review the changes, and push (this will start CProfileUpdater on lab5)
- now start publishing data with specific rate, by execute the following:
sudo ./publish.sh "1000" "15000" ./pubtransaction.conf

(This will pulish 15000 txns from each shard log file, with 1000micro seconds
delay between each txns, which effectively gives us the approximate rate of
1000msgs/sec)

- also start ./get_varz.py & 
(This will start collecting the cprofileupdater and cql varz every minute)

CAVEATS:
=======
- If you are running your terminal sessions in SCREEN, these scripts will not
  work due to screen + ssh issues. Run it on a terminal without screen.

- Also if you are running in single terminal session, run it as: 
'nohup sudo ./publish.sh "1000" "15000" ./pubtransaction.conf'
(This will not stop publishing when you close the terminal session on your
laptop)

- The publish rate that pubtransaction info log says isn't accurate, the
  actual rate of publishing will be close to the info log rate but not same,
  due to the time it takes to publish the data.

- Pubtransaction doesn't care about multi-tenancy parameters, so no need to
  add it to pubtransaction.conf if running the perf-setup in multi-tenancy
  mode.

- DO NOT run the perf setup with logging set to DEBUG, it could cause lots of
  components to crash and coredump. Crashes that i have seen is in VarzFetcher
  and SilverSurfer(very frequent crashes)
