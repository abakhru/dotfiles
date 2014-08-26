#!/bin/ksh -p

# cert.sh 0.6
#
# Generate an SSL server certificate for Messaging Server 6.x
# or later
#
# The SSL server certificate is created by first generating
# a self-signed Certificate Authority (CA) certificate.  That
# certificate is then used to sign an SSL server certificate
#
# While running, this script asks the following six questions:
#
#  1. Messaging Server directory [/opt/SUNWmsgsr]
#     To answer this question, provide the name of the directory
#     in which Messaging Server has been installed and for which
#     certificates are to be generated.
#
#  2. Certificate database password
#     Supply a case-sensitive password which will then be used
#     to secure the key database, <server-root>/config/key3.db.
#     THE KEY STROKES ENTERED FOR THE PASSWORD ARE ECHOED TO THE
#     TERMINAL.
#
#  3. Optional country code
#     Optionally supply the ISO country code for use in the
#     certificates' distinguished names.  For example, AU for
#     Australia, US for the United States, etc.
#
#  4. Organization name
#     Specify the organization name to use in the o= portion of
#     each certificate's distinguished name.  For example, Sun
#     Microsystems.
#
#  5. Organization's Internet domain name
#     Supply the organization's Internet domain name for use in
#     the cn= portion of the CA certificate's distinguished name.
#     For example, sun.com.  You can supply something other than
#     a domain name if you wish.
#
#  6. Fully qualified SSL server's Internet host name
#     The fully qualified Internet host name for the SSL server.
#     For example, imap.sun.com.
#
#     A wild card host name may be specified such as *.sun.com or
#     *.west.sun.com.
#
# Notes:
#
#  1. All generated files are placed in <server-root>/config.
#     Typically, this is the directory /opt/SUNWmsgsr/data/config
#     which is a link to the directory /var/opt/SUNWmsgs/config.
#
#  2. This script will exit if the certificate database (cert7.db),
#     key database (key3.db), or security module database (secmod.db)
#     already exist in <server-root>/config.
#
#  3. This script will produce two files containing the password
#     for the certificate and key databases:
#        <server-root>/config/sslpass.pw
#        <server-root>/config/sslpassword.conf
#     The first file is for convenience when running certutil, the
#     second is used by the Messaging Server's services to access
#     the databases while running.  The first file is deleted when
#     the script exits.  Both files are protected against group and
#     public access.
#
#  4. The generated certificates have a validity period of 10 years
#     and 2048 bit RSA keys.  This may be changed with the VALIDFOR
#     and KBIT variables.
#
#  5. As output, this script saves the CA and SSL server certificates
#     in ASCII files named SelfCA.cert and Server-Cert.cert.
#
#  6. Additionally, this script outputs make-cert.sh, a shell script
#     which may be used to regenerate the certificates (and keys) from
#     scratch.
#     

####################################################
#
# Create descriptor 4 as a dup of the original stdout.
# Functions which want to print user visible output
# to the original stdout have the option of using
# descriptor 4.
#
####################################################
exec 4>&1

# Commands and utilities we expect to use

typeset -r CHMOD="/usr/bin/chmod"
typeset -r CHOWN="/usr/bin/chown"
typeset -r GETFACL="/usr/bin/getfacl"
typeset -r RM="/usr/bin/rm"
typeset -r SED="/usr/bin/sed"
typeset -r TR="/usr/bin/tr"


# The noise files allow certutil to generate key pairs without
# requiring keyboard input.  You can changes these sources as
# you see appropriate.  Make into empty strings to use keyboard input.

NOISE_1="-z /dev/urandom"
NOISE_2="-z /dev/urandom"


# Nickname for the self-signed CA certificate
# May be changed if desired

CA_NICKNAME="SelfCA"


# Certificates are valid for 10 years

VALIDFOR="120"


# Certificates use 2048 bit RSA keys

KBITS="2048"


# The script will attempt to determine the UID and GID for Messaging
# Server from the $IMS_PATH/data/config directory.  The following
# two values are provided as defaults should the script be unable
# to determine this information.

MAILSRV_UID="mailsrv"
MAILSRV_GID="mail"


# The following routine determines if a string needs to be
# quoted when used in a distinguished name (DN).  Additionally,
# any leading and trailing whitespace is removed from the string.

quote()
{
    set -f
    typeset str="$(echo $*)"
    set +f

    # Remove any double or single quotes
    str="$(echo "${str}" | ${TR} -d "\'\"")"

    # Remove any leading or trailing whitespace
    str="$(echo "${str}" | ${SED} -e 's|^\ *||' | ${SED} -e 's|\ *$||')"

    # The string requires quoting if it contains ,.<>~!@#$%^*/\()?
    str2="$(echo ${str} | ${TR} -d "<>~!@#\$%^\*/\\()?,")"
    if [[ "${str}" != "${str2}" ]]; then
	str="\"${str}\""
    fi

    echo "${str}"

    return 0
}


# print_prompt text
#
#   text - the prompt
#
#   Print the given "text" as a prompt.
#
#   Return values:
#     0 - Always

print_prompt()
{
    set -f
    typeset text="$(echo $*)"
    set +f
    printf "%s " "${text}"
    return 0
}


# ask "prompt" "default" [many]
#
#   prompt  - the prompt tring
#   default - the default value
#   many    - answer can have multiple values
#
#   Display the prompt and return the user's answer.
#
#   If the trailing character of the prompt is ? or :, and
#   there is a "default", the trailer is re-positioned after
#   the "default".
#
#   The prompt is printed on file descriptor 4, and the answer
#   is printed to stdout.  File descriptor 4 should be
#   dupped to the original stdout before this function is called.
#
#   Return values:
#     0 - proceed
#     1 - ^D was typed

ask()
{
    set -f
    typeset prompt="$(echo ${1})"
    typeset default="${2}"
    typeset many="${3}"
    set +f

    typeset answer=
    typeset trailer
    typeset foo
    integer i

    # The caller of this function should have already opened
    # descriptor 4 as a dup of the original stdout.

    # Dup this function's stdout to descriptor 5.
    # Then, re-direct stdout to descriptor 4.

    # So, the default stdout from this function will go to
    # the original stdout (probably the tty).  Descriptor 5
    # has the answer printed to it.

    exec 5>&1
    exec 1>&4

    trailer=
    if [[ "${prompt}" = *\? ]]; then
	trailer="?"
    elif [[ "${prompt}" = *: ]]; then
	trailer=":"
    fi
    if [[ -n "${trailer}" ]]; then
	prompt="${prompt%${trailer}}"
	prompt="${prompt} [${default}]${trailer}"
    else
	prompt="${prompt} [${default}]"
    fi

    # Display the prompt and get the user's response
    # Loop until an answer is given.   Or, if there is a
    # default, the user need not supply an answer.

    let i=0
    while true
    do
	# If this is not the first time through, beep
	[[ ${i} -gt 0 ]] && echo "\c"
	let i=1

	# Prompt and get response
	print_prompt "${prompt}"
	if [[ -n "${many}" ]]; then
	   read answer
           foo=
        else
	   read answer foo
        fi

	# Return 1 on EOF
	if [[ $? -eq 1 ]]; then
	    echo
	    return 1
	fi

	# If more than one arg, repeat prompt
	if [[ -n "${foo}" ]]; then
	    continue
	fi

	# If no answer and default, default is the answer
	if [[ -z "${answer}" ]]; then
	    answer="${default}"
	fi

	# Okay
	break
    done

    echo "${answer}" >&5

    return 0
}

# Set up the prompts for the questions we will be asking

typeset -x TEXTDOMAIN=
typeset -x TEXTDOMAINDIR=
PR_DIR="$(gettext "Messaging Server directory")"
PR_PWD="$(gettext "Certificate database password")"
PR_CA_C="$(gettext "Optional country code")"
PR_CA_O="$(gettext "Organization name")"
PR_CA_CN="$(gettext "Organization's Internet domain name")"
PR_SVR_CN="$(gettext "Fully qualified SSL server's Internet host name")"

# Get the absolute path to the Messaging Server diretctory

IMS_PATH="/opt/SUNWmsgsr"
IMS_PATH="$(ask "${PR_DIR}:" "${IMS_PATH}")" || return 1

# Exit now if we cannot locate the certutil utility

CERTUTIL="${IMS_PATH}/sbin/certutil"
if [ ! -x "${CERTUTIL}" ]; then
    echo "Unable to locate the certutil utility.  It should be the executable" \
         "file named"
    echo ""
    echo "  ${CERTUTIL}"
    echo ""
    exit 1
fi

# Exit now if we cannot locate the configutil utility

CONFIGUTIL="${IMS_PATH}/sbin/configutil"
if [ ! -x "${CONFIGUTIL}" ]; then
    echo "Unable to locate the configutil utility.  It should be the executable" \
         "file named"
    echo ""
    echo "  ${CONFIGUTIL}"
    echo ""
    exit 1
fi

# Exit if key3.db or cert7.db already exist

DB_DIR="${IMS_PATH}/config"
if [[ -f "${DB_DIR}/key3.db" ]]; then
    echo "A key database,"
    echo ""
    echo "  ${DB_DIR}/key3.db"
    echo ""
    echo "already exists."
    exit 1
fi
if [[ -f "${DB_DIR}/cert7.db" ]]; then
    echo "A certificate database,"
    echo ""
    echo "  ${DB_DIR}/cert7.db"
    echo ""
    echo "already exists."
    exit 1
fi

# Now for some more questions

DEF_DOMAIN="$(${IMS_PATH}/sbin/configutil -o local.defdomain)"
DEF_HOST="$(${IMS_PATH}/sbin/configutil -o local.hostname)"

# Country code

C="$(ask "${PR_CA_C}:" "")" || return 1
if [[ -n "${C}" ]]; then
    C="$(echo "${C}" | ${TR} '[:lower:]' '[:upper:]')"
    C="$(quote "${C}")"
fi

# Organization

O="$(ask "${PR_CA_O}:" "Internet Widgets, Ltd." "many")" || return 1
O="$(quote "${O}")"

# Common name

CN="$(ask "${PR_CA_CN}:" "${DEF_DOMAIN}")" || return 1
CN="$(quote "${CN}")"

# Server name

while true
do
    SRV="$(ask "${PR_SVR_CN}:" "${DEF_HOST}")" || return 1
    SRV2="$(echo "${SRV}" | ${TR} -d ".")"
    if [[ "${SRV}" == "${SRV2}" ]]; then
	printf "$(gettext \
	  "Please specify a fully qualified domain name (e.g., mail.sun.com)")\n"
	continue;
    fi
    break
done
SRV="$(quote "${SRV}")"

# Password for the certificate database
while true
do
    PASSWORD="$(${IMS_PATH}/lib/unique_id)"
    PASSWORD="$(ask "${PR_PWD}:" "${PASSWORD}")" || return 1
    if [[ -z "${PASSWORD}" ]]; then
	printf "$(gettext "The password must not be an empty string")"
	continue
    fi
    break
done

printf "$(gettext "Generating files...")\n"

# Determine the UID and GID for Messaging Server

ACL_FILE="${IMS_PATH}/data/config/acl.TMP"
${GETFACL} ${IMS_PATH}/data/config > ${ACL_FILE}
if [[ $? -eq 0 ]]; then
  UID="$(${SED} -n -e 's|^# *owner: *\(.*\)$|\1|p' < ${ACL_FILE})"
  GID="$(${SED} -n -e 's|^# *group: *\(.*\)$|\1|p' < ${ACL_FILE})"
  ${RM} ${ACL_FILE}
else
  UID="${MAILSRV_UID}"
  GID="${MAILSRV_GID}"
fi

DB_PWFILE="${IMS_PATH}/data/config/sslpass.pw"
SSL_PWFILE="${IMS_PATH}/data/config/sslpassword.conf"
printf "$(gettext "Creating %s")\n" "${DB_PWFILE}"
echo ${PASSWORD} > ${DB_PWFILE}
printf "$(gettext "Creating %s")\n" "${SSL_PWFILE}"
echo "Internal (Software) Token:${PASSWORD}" > ${SSL_PWFILE}
${CHOWN} ${UID}:${GID} ${DB_PWFILE} ${SSL_PWFILE}
${CHMOD} 0600 ${DB_PWFILE} ${SSL_PWFILE}
PASSWORD=""

# Generate the databases cert7.db, key3.db, and secmod.db

printf "$(gettext "Creating %s")\n" "${DB_DIR}/cert7.db, key3.db, and secmod.db"
${CERTUTIL} -N -d ${DB_DIR} -f ${DB_PWFILE}
${CHOWN} ${UID}:${GID} ${DB_DIR}/cert7.db ${DB_DIR}/key3.db ${DB_DIR}/secmod.db
${CHMOD} 0600 ${DB_DIR}/cert7.db ${DB_DIR}/key3.db ${DB_DIR}/secmod.db

# Generate our own self-signed Certificate Authority (CA) certificate.

printf "$(gettext "Generating the self-signed CA certificate \"%s\"")\n" \
    "${CA_NICKNAME}"
CA_DN="cn=${CN},o=${O}"
if [[ -n "${C}" ]]; then
    CA_DN="${CA_DN},c=${C}"
fi
${CERTUTIL} -S -d ${DB_DIR} -n ${CA_NICKNAME} -s "${CA_DN}" \
  -g ${KBITS} -t "CTu,CTu,CTu" -v ${VALIDFOR} -x -f ${DB_PWFILE} ${NOISE_1}
printf \
  "$(gettext "Saving an ASCII form of the CA certificate in the file\n    %s")\n" \
  "${DB_DIR}/${CA_NICKNAME}.cert"
${CERTUTIL} -L -d ${DB_DIR} -n ${CA_NICKNAME} -a > ${DB_DIR}/${CA_NICKNAME}.cert
${CHOWN} ${UID}:${GID} ${DB_DIR}/${CA_NICKNAME}.cert
${CHMOD} 0600 ${DB_DIR}/${CA_NICKNAME}.cert

# Generate a server certificate; sign it using the self-signed CA cert
# Note that the certificate nickname "Server-Cert" is the default certificate
# used by the assorted servers in Messaging Server.
# Use /var/adm/messages as a source of noise when generating the key pair

if [[ -x "${IMS_PATH}/sbin/configutil" ]]; then
  CERT_NICKNAME="$(${IMS_PATH}/sbin/configutil -o encryption.rsa.nssslpersonalityssl)"
  if [[ -z "${CERT_NICKNAME}" ]]; then
    CERT_NICKNAME="Server-Cert"
  fi
else
  CERT_NICKNAME="Server-Cert"
fi

printf "$(gettext "Generating the SSL server certificate \"%s\"")\n" \
    "${CERT_NICKNAME}"
DN="cn=${SRV},o=${O}"
if [[ -n "${C}" ]]; then
    DN="${DN},c=${C}"
fi
${CERTUTIL} -S -d ${DB_DIR} -n ${CERT_NICKNAME} -s "${DN}" \
  -g ${KBITS} -t "u,u,u" -v ${VALIDFOR} -c ${CA_NICKNAME} -f ${DB_PWFILE} \
  ${NOISE_2}
${RM} ${DB_PWFILE}
printf "$(gettext \
  "Saving an ASCII form of the SSL server certificate in the file\n    %s")\n" \
  "${DB_DIR}/${CERT_NICKNAME}.cert"
${CERTUTIL} -L -d ${DB_DIR} -n ${CERT_NICKNAME} \
  -a > ${DB_DIR}/${CERT_NICKNAME}.cert
${CHOWN} ${UID}:${GID} ${DB_DIR}/${CERT_NICKNAME}.cert
${CHMOD} 0600 ${DB_DIR}/${CERT_NICKNAME}.cert

echo "#!/bin/sh" >make-cert.sh
echo "${SED} -e 's|Software (Internal) Token:||' < \\" >>make-cert.sh
echo "    ${DB_DIR}/sslpassword.conf > ${DB_DIR}/sslpass.pw" >>make-cert.sh
echo "${CHOWN} ${UID}:${GID} ${DB_DIR}/sslpass.pw" >>make-cert.sh
echo "${CHMOD} 0600 ${DB_DIR}/sslpass.pw" >>make-cert.sh
echo "" >>make-cert.sh 
echo "${CERTUTIL} -N -d ${DB_DIR} \\" >>make-cert.sh
echo "    -f ${DB_PWFILE}" >> make-cert.sh
echo "${CHOWN} ${UID}:${GID} ${DB_DIR}/cert7.db \\" >>make-cert.sh
echo "    ${DB_DIR}/key3.db \\" >>make-cert.sh
echo "    ${DB_DIR}/secmod.db" >>make-cert.sh
echo "${CHMOD} 0600 ${DB_DIR}/cert7.db \\" >>make-cert.sh
echo "    ${DB_DIR}/key3.db \\" >>make-cert.sh
echo "    ${DB_DIR}/secmod.db" >>make-cert.sh
echo "" >>make-cert.sh
echo "${CERTUTIL} -S -d ${DB_DIR} -n ${CA_NICKNAME} \\" >>make-cert.sh
echo "    -s '${CA_DN}' \\" >>make-cert.sh
echo "    -t \"CTu,CTu,CTu\" -v ${VALIDFOR} -g ${KBITS} -x \\" >>make-cert.sh
echo "    -f ${DB_PWFILE} ${NOISE_1}" >>make-cert.sh
echo "${CERTUTIL} -L -d ${DB_DIR} -n ${CA_NICKNAME} -a > \\" >>make-cert.sh
echo "    ${DB_DIR}/${CA_NICKNAME}.cert" >>make-cert.sh
echo "${CHOWN} ${UID}:${GID} ${DB_DIR}/${CA_NICKNAME}.cert" >>make-cert.sh
echo "${CHMOD} 0600 ${DB_DIR}/${CA_NICKNAME}.cert" >>make-cert.sh
echo "" >>make-cert.sh
echo "${CERTUTIL} -S -d ${DB_DIR} -n ${CERT_NICKNAME} \\" >>make-cert.sh
echo "    -s '${DN}' \\" >>make-cert.sh
echo "    -t \"u,u,u\" -v ${VALIDFOR} -g ${KBITS} -c ${CA_NICKNAME} \\" >>make-cert.sh
echo "    -f ${DB_PWFILE} ${NOISE_2}" >>make-cert.sh
echo "${RM} ${DB_DIR}/sslpass.pw" >>make-cert.sh
echo "${CERTUTIL} -L -d ${DB_DIR} -n ${CERT_NICKNAME} -a > \\" >>make-cert.sh
echo "  ${DB_DIR}/${CERT_NICKNAME}.cert" >>make-cert.sh
echo "${CHOWN} ${UID}:${GID} ${DB_DIR}/${CERT_NICKNAME}.cert" >>make-cert.sh
echo "" >>make-cert.sh
echo "${CHMOD} 0600 ${DB_DIR}/${CERT_NICKNAME}.cert" >>make-cert.sh
${CHOWN} ${UID}:${GID} make-cert.sh
${CHMOD} 0700 make-cert.sh

# Done
printf "$(gettext "Done")\n"

exit 0


