#!/bin/ksh

/usr/bin/uname -r
if [ `/usr/bin/uname -r` == "5.10" ]; then
   echo "Please dont use this script for uninstalling JES from Sol10 Machine"
   exit 1
fi
