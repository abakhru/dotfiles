dir=`pwd`
cd /usr/sfw/lib/
openssl ocsp -index /space/smime/index.txt -CA /space/smime/newcerts/cacert.pem -port 8888 -rkey $dir/ocsp-key.pem -rsigner $dir/ocsp-cert.pem -resp_no_certs -nmin 60 -text 2>$dir/ocsp.log >/dev/null &
echo "`ps -ef|grep openssl|awk '{print $2}'`" > $dir/ocsp.pid
cd $dir
