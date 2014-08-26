#!/bin/bash
if [ $# -ne 2 ]
then
echo "Usage: $0 <command_to_execute_on_remote_machine> <machine_list_file>"
exit 0
fi
for i in `more $2`
do 
./remote_script.sh "$1" $i
done 2>err >output
