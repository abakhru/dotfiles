top > /tmp/t; n=`cat /tmp/t |wc -l`; b=$(expr $n - 6); tail -$b /tmp/t | awk '{printf "%s\t%s\n", $10,$11;}'
