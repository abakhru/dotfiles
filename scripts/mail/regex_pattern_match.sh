for i in `\ls *.exp`; do sed 's/^/\//' $i > t; mv t $i; done
for i in `\ls *.exp`; do sed 's/$/\//' $i > t; mv t $i; done
for i in `\ls *.exp`; do sed 's/(/\\(/g' $i > t; mv t $i; done
for i in `\ls *.exp`; do sed 's/)/\\)/g' $i > t; mv t $i; done
for i in `\ls *.exp`; do sed 's/*/\\*/g' $i > t; mv t $i; done
for i in `\ls *.exp`; do sed 's/\[/\\\[/' $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed 's/\]/\\\]/' $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed "s/\\HasNoChildren/\\\\HasNoChildren/" $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed "s/\\HasChildren/\\\\HasChildren/" $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed "s/\\NoInferiors/\\\\NoInferiors/" $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed "s/\\Recent/\\\\Recent/" $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed "s/\\Answered/\\\\Answered/" $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed "s/\\Flagged/\\\\Flagged/" $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed "s/\\Draft/\\\\Draft/" $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed "s/\\Deleted/\\\\Deleted/" $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed "s/\\Seen/\\\\Seen/" $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed 's/\/\//\//' $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed 's/UIDVALIDITY/UIDVALIDITY\//' $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed 's/UIDNEXT/UIDNEXT\//' $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed 's/\]  \//\]\//' $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed 's/User logged/User\/ logged/' $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed 's/\"/\\\"/g' $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed 's/\"\//\"\\\//' $i > t1; mv t1 $i; done
#for i in `\ls *.exp`; do sed '/PERMANENTFLAGS/ s/Seen \\\*/Seen \\\\\\\*/' $i > t1; mv t1 $i; done
for i in `\ls *.exp`; do sed '/PERMANENTFLAGS/ s/Seen \\\*/Seen \\\\\\\\\*/' $i > t1; mv t1 $i; done
