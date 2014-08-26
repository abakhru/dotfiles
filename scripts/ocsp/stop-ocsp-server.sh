dir=`pwd`
for i in `cat $dir/ocsp.pid`
do
kill -9 $i 2>/dev/null >/dev/null
done
rm $dir/ocsp.pid
