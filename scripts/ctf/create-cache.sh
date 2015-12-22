#!/bin/bash

FILES_PCAP=`ls *.pcap`

mkdir tcpprep-cache
for f in $FILES_PCAP
do
tcpprep --auto=bridge --pcap=$f --cachefile=tcpprep-cache/$f.cache
done
