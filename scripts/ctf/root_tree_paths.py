# response
curl -s -k -X POST http://localhost:8080/rsa/tree/node/get -H "Content-Type: application/json" -d '{"path":"/rsa"}'

# launch-esa
curl -s -k -X POST https://localhost:8080/rsa/tree/node/get -H "Content-Type: application/json" -d '{"path":"/rsa"}'
{"path": "/rsa/metrics/name/rsa/analytics/http-packet/c2/c2-1/processed-count"}

{"path": "/rsa/sys/jvm"}
{"path": "/rsa/sys/jvm/memory"}
{"path": "/rsa/sys/jvm/memory/total/used"}

Could not connect to [1.8.0_91] ./analytics/server/target/esa-analytics-server-11.0.0.0-SNAPSHOT-executable.jar (36502) : Exception creating connection to: fe80:0:0:0:7ca5:3cff:fe84:b7f4%8; nested exception is:
	java.net.SocketException: Protocol family unavailable
Could not connect to [1.8.0_91] ./analytics/server/target/esa-analytics-server-11.0.0.0-SNAPSHOT-executable.jar (36502). Make sure the JVM is running and that you are using the correct protocol in the Service URL (service:jmx:rmi://127.0.0.1/stub/rO0ABXN9AAAAAQAlamF2YXgubWFuYWdlbWVudC5yZW1vdGUucm1pLlJNSVNlcnZlcnhyABdqYXZhLmxhbmcucmVmbGVjdC5Qcm94eeEn2iDMEEPLAgABTAABaHQAJUxqYXZhL2xhbmcvcmVmbGVjdC9JbnZvY2F0aW9uSGFuZGxlcjt4cHNyAC1qYXZhLnJtaS5zZXJ2ZXIuUmVtb3RlT2JqZWN0SW52b2NhdGlvbkhhbmRsZXIAAAAAAAAAAgIAAHhyABxqYXZhLnJtaS5zZXJ2ZXIuUmVtb3RlT2JqZWN002G0kQxhMx4DAAB4cHdLAAtVbmljYXN0UmVmMgAAIGZlODA6MDowOjA6N2NhNTozY2ZmOmZlODQ6YjdmNCU4AADRv8OEFdGu7brFPdRP4QAAAVWeoXcIgAEAeA==).

get-node '{"path": "/rsa/sys/jvm"}' |python -m json.tool |grep path


curl -X POST https://asoc-jenkins.rsa.lab.emc.com/job/ana-ctf-single-test/buildWithParameters?token=capthook\&BUILD_BRANCH=master\&FORK=bakhra/launch-esa\&CTF_BRANCH=master

curl -X POST https://asoc-jenkins.rsa.lab.emc.com/job/ana-ctf-single-test/buildWithParameters?token=capthook&BUILD_BRANCH=master&FORK=bakhra/launch-esa&CTF_BRANCH=master
