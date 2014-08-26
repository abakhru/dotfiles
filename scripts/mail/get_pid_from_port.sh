#!/bin/bash
# is the port we are looking for

if [ $# -lt 1 ]
then
echo "Please provide a port number parameter for this script"
echo "e.g. %content 1521"
exit
fi

echo "Greping for your port, please be patient (CTRL+C breaks) . "

for i in `\ls /proc`
do
pfiles $i | grep AF_INET | grep $1
if [ $? -eq 0 ]
then
echo Is owned by pid $i
echo The pid detailed information is as follows..
ps -ef |grep $i
fi
done
