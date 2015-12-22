#!/bin/bash
# ./fix_java_alternatives.sh

# Create commands to remove existing alternatives
/usr/sbin/alternatives --display "java" | \
    awk '/priority/ {print $1}' |\
    xargs -I {} echo "/usr/sbin/alternatives --remove \"java\" \"{}\"" > /tmp/fix_java_alternatives.sh
echo -e " " >> /tmp/fix_java_alternatives.sh

# Find installed java binaries using the find command at the two likely CentOS installation points
javas=( $(find /usr/lib/jvm -type f -name 'java' | grep -v 'jre/bin') $(find /usr/java -type f -name 'java' | egrep -v 'jre/bin') )

# Find version based priorities for the java binaries
for j in ${javas[@]}; do
    # Get the priority of the version
    prio=$(echo $j | sed -e 's#/bin/java##' -e 's#/usr/.*/\(.*\)$#\1#' -e 's/^jdk//' \
                         -e 's/^.*-openjdk-\(.*\)\.x86_64/\1/' \
                         -e 's/\(.*\)-[0-9]\..*/\1/' -e 's/_/./' -e 's/\.//g' \
                         -e 's/\(.*\)-.*$/\1/')
    # Create the alternatives install command
    echo "/usr/sbin/alternatives --install \"/usr/bin/java\" \"java\" \"${j}\" ${prio}" >> /tmp/fix_java_alternatives.sh
done
