#!/bin/bash

if [ $# -lt 1 ]
then
echo 'Usage: pcap_injection.sh interface'
echo 'Ex: pcap_injectio.sh em1'
exit 2
fi

while [ true ]
do

FILES_PCAP=`ls *.pcap`

for f__ in $FILES_PCAP
do

iprand1=`perl -le '$,=".";print map int rand 256,1..4'`
iprand2=`perl -le '$,=".";print map int rand 256,1..4'`
echo "processing pcap file..." $f__
echo "$iprand1 <-----> $iprand2"
tcpreplay-edit -t  --intf1=$1  --endpoints=$iprand1:$iprand2 --cachefile=tcpprep-cache/$f__.cache $f__
done
sleep 1

done
