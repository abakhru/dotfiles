#set -x
if [ $# -ne 1 ]
then
echo "Please enter the username & password"
echo "Usage: $0 <base64 encoded data>"
exit 0
fi

encoded=$1
tail -1 $0 > t
sed -e 's/#//' t > b
sed -e "s/encoded_data/$encoded/g" b > a
sh a
rm b t a
#perl -MMIME::Base64 -e 'print decode_base64("encoded_data");';
