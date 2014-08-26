#/bin/bash -x
dir=`pwd`;
wget --debug --save-cookies $dir/cookies.txt --http-user="amit.bakhru@oracle.com" --http-password="(Pr0metheus\\" "https://login.oracle.com/mysso/signon.jsp"
TOKEN=`cat FileBrowsePage* |grep value|cut -d"\"" -f4`

wget --debug --keep-session-cookies --load-cookies $dir/cookies.txt "http://files.oraclecorp.com/content/AllPublic/Users/Users-W/wifiadmin_us-Public/airespace_pwd.txt"
#wget --debug --keep-session-cookies "http://files.oraclecorp.com/content/AllPublic/Users/Users-W/wifiadmin_us-Public/airespace_pwd.txt"

#rm $dir/cookies*
