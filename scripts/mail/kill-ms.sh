kill -9 `ps -ef|grep watcher|awk '{print $2}'|head -1`
for i in `ps -eaf |grep -i messaging64|grep -v appserver |awk '{ print $2 }'`; do kill -9 $i; done
