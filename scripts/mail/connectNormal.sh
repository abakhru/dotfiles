#!/bin/bash
if [ $# -ne 3 ]
then 
echo "Usage: $0 mailhost user port"
exit 0
fi

if [ $3 -eq 25 ] || [ $3 -eq 125 ]; then
	./expect_scripts/smtp_expect.sh $1 $2 $3
elif [ $3 -eq 110 ] || [ $3 -eq 1110 ]; then
	./expect_scripts/pop_expect.sh $1 $2 $3
elif [ $3 -eq 143 ] || [ $3 -eq 1143 ]; then
	./expect_scripts/imap_expect.sh $1 $2 $3
fi
