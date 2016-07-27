#!/bin/bash
whois_host="https://cms.netwitness.com"

if [[ $# -eq 0 ]] ; then
    echo "$0 requires at least the name of the domain to look up"
    exit 1
fi

domain=$1
username=${2:-"authenticatedliveuser"}
password=${3:-"NetwitnessAndRSA123!!"}
# Authorize your access using a POST of the login parameters
auth_data="{\"X-Auth-Username\":\"${username}\",\"X-Auth-Password\":\"${password}\"}"
echo "auth_data = ${auth_data}"
auth_header="Content-Type: application/json"
auth_path="authlive/authenticate/WHOIS"
resp_headers_file=`mktemp ./resp_headers.XXXXXX`
echo "curl -sk -H \"${auth_header}\" -X POST -d \"${auth_data}\" \"${whois_host}/${auth_path}\" -D ${resp_headers_file} -o /dev/null"
curl -sk -H "${auth_header}" -X POST -d "${auth_data}" "${whois_host}/${auth_path}" -D ${resp_headers_file} -o /dev/null
auth_token_header=$(cat ${resp_headers_file} | tr -d '\r' | grep '^X-Auth-Token:')

# if $1 == "malformed" I'm going to break the url instead
if [ "${domain}" == "malformed" ]; then
    domain="dx/${domain}"
fi
# Do the query now
query_path="whois/query/$domain"
echo "Authorization header: ${auth_header}"
echo "${whois_host}/${query_path}"
echo "curl -sk -H \"${auth_header}\" -H \"${auth_token_header}\" \"${whois_host}/${query_path}\" | tr -d '\r' | python -m
json.tool"
curl -sk -H "${auth_header}" -H "${auth_token_header}" "${whois_host}/${query_path}" -D ${resp_headers_file} | tr -d '\r' |
python -m json.tool
echo "Response Headers:"
cat ${resp_headers_file} | sed -e 's/^/    /'
rm -f ${resp_headers_file}
