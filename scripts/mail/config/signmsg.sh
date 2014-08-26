#!/bin/sh -x

time=`date '+20%y%m%d%H%M%S'`
SMIME_DIR=/space/smime
CERT_DIR=$SMIME_DIR/newcerts
LOGFILE=/var/opt/sun/comms/messaging/log/smime$time.log
echo "" >$LOGFILE

PID=$$

# get envelope from
USER=`awk '/X-Envelope-from/ {print $2}' $INFO_FILE`

# log
echo "---- invoked ---" >> $LOGFILE
echo "* INFO_FILE is $INFO_FILE" >> $LOGFILE
echo "* INPUT_FILE is $INPUT_FILE" >> $LOGFILE
echo "* OUTPUT_FILE is $OUTPUT_FILE" >> $LOGFILE
echo "* OUTPUT_OPTIONS is $OUTPUT_OPTIONS" >> $LOGFILE
echo "* X-envelope-from is $USER" >> $LOGFILE
echo "* INFO_FILE follows:" >> $LOGFILE
cat $INFO_FILE >> $LOGFILE
echo "* OUTPUT_OPTIONS follows:" >> $LOGFILE
cat $OUTPUT_OPTIONS >> $LOGFILE
echo "* INPUT_FILE follows:" >> $LOGFILE
cat $INPUT_FILE >> $LOGFILE
echo "* End of INPUT_FILE" >> $LOGFILE

# check for a cert for this user
# each user has a directory under $SMIME_DIR/certs
# if no cert exists, then pass the message through unsigned
if [ ! -r "/space/smime/private/neo8-key.pem" ] ; then
        echo "* No cert dir found for $USER.  Not signing message." >> $LOGFILE
        cat $INPUT_FILE > $OUTPUT_FILE
else
        echo "* Signing with cert for $USER" >> $LOGFILE
        openssl smime -sign \
        -inkey /space/smime/private/neo8-key.pem \
        -signer /space/smime/newcerts/neo8-cert.pem \
        -certfile /space/smime/newcerts/neo8-cert.pem \
        -in $INPUT_FILE | tr -d "\r" > $OUTPUT_FILE

	cp $OUTPUT_FILE $INPUT_FILE
	echo "OPEN INPUT_FILE"
	cat $INPUT_FILE
#        | tr -d "\r" > $SMIME_DIR/.a
#	cp $SMIME_DIR/.a $OUTPUT_FILE
#	rm $SMIME_DIR/.a
#        cat $INPUT_FILE > ${OUTPUT_FILE}
#	echo "AMIT" >> $OUTPUT_FILE
fi

echo "* OUTPUT_FILE follows" >> $LOGFILE
cat $OUTPUT_FILE >> $LOGFILE
echo "* End of OUTPUT_FILE" >> $LOGFILE

echo "---- done ----" >> $LOGFILE
#return
