#!/bin/sh -x
#
# File: append_disclaimer.sh
#
# Usage:
# append_disclaimer.sh [-debug] "name-of-disclaimer-text-file"
#
# References:
# http://docs.sun.com/source/816-6009-10/channel2.htm#42323
# http://docs.sun.com/source/816-6009-10/channel2.htm#42402
#

if [ "$1" = "-debug" ]
then
shift
set -x
fi

DISCLAIMER_FILE=$1
DISCLAIMER_FILE=/var/opt/sun/comms/messaging/site-programs/${DISCLAIMER_FILE}

TAG="Standard Disclaimer Appended `date`"

cp $INPUT_FILE $OUTPUT_FILE # copy original message part to output destination

# See if the message was already tagged.
grep "Comments: Standard Disclaimer Appended" $MESSAGE_HEADERS >/dev/null
if [ $? -ne 0 ]
then
# add a blank line
echo "" >> $OUTPUT_FILE

# append the disclaimer
cat $DISCLAIMER_FILE >> $OUTPUT_FILE

# Set a directive so the message will be tagged
#echo "OUTPUT_DIAGNOSTIC=${TAG}" >> $OUTPUT_OPTIONS
fi

# end script
