function zsh_stats() {
  fc -l 1 | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl |  head -n20
}

function uninstall_oh_my_zsh() {
  /usr/bin/env ZSH=$ZSH /bin/sh $ZSH/tools/uninstall.sh
}

function upgrade_oh_my_zsh() {
  /usr/bin/env ZSH=$ZSH /bin/sh $ZSH/tools/upgrade.sh
}

function take() {
  mkdir -p $1
  cd $1
}

#
# Get the value of an alias.
#
# Arguments:
#    1. alias - The alias to get its value from
# STDOUT:
#    The value of alias $1 (if it has one).
# Return value:
#    0 if the alias was found,
#    1 if it does not exist
#
function alias_value() {
    alias "$1" | sed "s/^$1='\(.*\)'$/\1/"
    test $(alias "$1")
}

#
# Try to get the value of an alias,
# otherwise return the input.
#
# Arguments:
#    1. alias - The alias to get its value from
# STDOUT:
#    The value of alias $1, or $1 if there is no alias $1.
# Return value:
#    Always 0
#
function try_alias_value() {
    alias_value "$1" || echo "$1"
}

#
# Set variable "$1" to default value "$2" if "$1" is not yet defined.
#
# Arguments:
#    1. name - The variable to set
#    2. val  - The default value 
# Return value:
#    0 if the variable exists, 3 if it was set
#
function default() {
    test `typeset +m "$1"` && return 0
    typeset -g "$1"="$2"   && return 3
}

#
# Set enviroment variable "$1" to default value "$2" if "$1" is not yet defined.
#
# Arguments:
#    1. name - The env variable to set
#    2. val  - The default value 
# Return value:
#    0 if the env variable exists, 3 if it was set
#
function env_default() {
    env | grep -q "^$1=" && return 0 
    export "$1=$2"       && return 3
}
# Simple calculator
function calc() {
	local result=""
	result="$(printf "scale=10;$*\n" | bc --mathlib | tr -d '\\\n')"
	#                       └─ default (when `--mathlib` is used) is 20
	#
	if [[ "$result" == *.* ]]; then
		# improve the output for decimal numbers
		printf "$result" |
		sed -e 's/^\./0./'        `# add "0" for cases like ".5"` \
		    -e 's/^-\./-0./'      `# add "0" for cases like "-.5"`\
		    -e 's/0*$//;s/\.$//'   # remove trailing zeros
	else
		printf "$result"
	fi
	printf "\n"
}

# Create a new directory and enter it
function mkd() {
	mkdir -p "$@" && cd "$@"
}

# Change working directory to the top-most Finder window location
function cdf() { # short for `cdfinder`
	cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')"
}

# Create a .tar.gz archive, using `zopfli`, `pigz` or `gzip` for compression
function targz() {
	local tmpFile="${@%/}.tar"
	tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1

	size=$(
		stat -f"%z" "${tmpFile}" 2> /dev/null; # OS X `stat`
		stat -c"%s" "${tmpFile}" 2> /dev/null # GNU `stat`
	)

	local cmd=""
	if (( size < 52428800 )) && hash zopfli 2> /dev/null; then
		# the .tar file is smaller than 50 MB and Zopfli is available; use it
		cmd="zopfli"
	else
		if hash pigz 2> /dev/null; then
			cmd="pigz"
		else
			cmd="gzip"
		fi
	fi

	echo "Compressing .tar using \`${cmd}\`…"
	"${cmd}" -v "${tmpFile}" || return 1
	[ -f "${tmpFile}" ] && rm "${tmpFile}"
	echo "${tmpFile}.gz created successfully."
}

# Determine size of a file or total size of a directory
function fs() {
	if du -b /dev/null > /dev/null 2>&1; then
		local arg=-sbh
	else
		local arg=-sh
	fi
	if [[ -n "$@" ]]; then
		du $arg -- "$@"
	else
		du $arg .[^.]* *
	fi
}

# Use Git’s colored diff when available
hash git &>/dev/null
if [ $? -eq 0 ]; then
	function diff() {
		git diff --no-index --color-words "$@"
	}
fi

# Create a data URL from a file
function dataurl() {
	local mimeType=$(file -b --mime-type "$1")
	if [[ $mimeType == text/* ]]; then
		mimeType="${mimeType};charset=utf-8"
	fi
	echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Create a git.io short URL
function gitio() {
	if [ -z "${1}" -o -z "${2}" ]; then
		echo "Usage: \`gitio slug url\`"
		return 1
	fi
	curl -i http://git.io/ -F "url=${2}" -F "code=${1}"
}

# Start an HTTP server from a directory, optionally specifying the port
function server() {
	local port="${1:-8000}"
	sleep 1 && open "http://localhost:${port}/" &
	# Set the default Content-Type to `text/plain` instead of `application/octet-stream`
	# And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
	python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
}

# Start a PHP server from a directory, optionally specifying the port
# (Requires PHP 5.4.0+.)
function phpserver() {
	local port="${1:-4000}"
	local ip=$(ipconfig getifaddr en1)
	sleep 1 && open "http://${ip}:${port}/" &
	php -S "${ip}:${port}"
}

# Compare original and gzipped file size
function gz() {
	local origsize=$(wc -c < "$1")
	local gzipsize=$(gzip -c "$1" | wc -c)
	local ratio=$(echo "$gzipsize * 100/ $origsize" | bc -l)
	printf "orig: %d bytes\n" "$origsize"
	printf "gzip: %d bytes (%2.2f%%)\n" "$gzipsize" "$ratio"
}

# Syntax-highlight JSON strings or files
# Usage: `json '{"foo":42}'` or `echo '{"foo":42}' | json`
function json() {
	if [ -t 0 ]; then # argument
		python -mjson.tool <<< "$*" | pygmentize -l javascript
	else # pipe
		python -mjson.tool | pygmentize -l javascript
	fi
}

# All the dig info
function digga() {
	dig +nocmd "$1" any +multiline +noall +answer
}

# Escape UTF-8 characters into their 3-byte format
function escape() {
	printf "\\\x%s" $(printf "$@" | xxd -p -c1 -u)
	# print a newline unless we’re piping the output to another program
	if [ -t 1 ]; then
		echo # newline
	fi
}

# Decode \x{ABCD}-style Unicode escape sequences
function unidecode() {
	perl -e "binmode(STDOUT, ':utf8'); print \"$@\""
	# print a newline unless we’re piping the output to another program
	if [ -t 1 ]; then
		echo # newline
	fi
}

# Get a character’s Unicode code point
function codepoint() {
	perl -e "use utf8; print sprintf('U+%04X', ord(\"$@\"))"
	# print a newline unless we’re piping the output to another program
	if [ -t 1 ]; then
		echo # newline
	fi
}

# Show all the names (CNs and SANs) listed in the SSL certificate
# for a given domain
function getcertnames() {
	if [ -z "${1}" ]; then
		echo "ERROR: No domain specified."
		return 1
	fi

	local domain="${1}"
	echo "Testing ${domain}…"
	echo # newline

	local tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
		| openssl s_client -connect "${domain}:443" 2>&1);

	if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
		local certText=$(echo "${tmp}" \
			| openssl x509 -text -certopt "no_header, no_serial, no_version, \
			no_signame, no_validity, no_issuer, no_pubkey, no_sigdump, no_aux");
			echo "Common Name:"
			echo # newline
			echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//";
			echo # newline
			echo "Subject Alternative Name(s):"
			echo # newline
			echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
				| sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2
			return 0
	else
		echo "ERROR: Certificate not found.";
		return 1
	fi
}

# Add note to Notes.app (OS X 10.8)
# Usage: `note 'title' 'body'` or `echo 'body' | note`
# Title is optional
function note() {
	local title
	local body
	if [ -t 0 ]; then
		title="$1"
		body="$2"
	else
		title=$(cat)
	fi
	osascript >/dev/null <<EOF
tell application "Notes"
	tell account "iCloud"
		tell folder "Notes"
			make new note with properties {name:"$title", body:"$title" & "<br><br>" & "$body"}
		end tell
	end tell
end tell
EOF
}

# Add reminder to Reminders.app (OS X 10.8)
# Usage: `remind 'foo'` or `echo 'foo' | remind`
function remind() {
	local text
	if [ -t 0 ]; then
		text="$1" # argument
	else
		text=$(cat) # pipe
	fi
	osascript >/dev/null <<EOF
tell application "Reminders"
	tell the default list
		make new reminder with properties {name:"$text"}
	end tell
end tell
EOF
}

# Manually remove a downloaded app or file from the quarantine
function unquarantine() {
	for attribute in com.apple.metadata:kMDItemDownloadedDate com.apple.metadata:kMDItemWhereFroms com.apple.quarantine; do
		xattr -r -d "$attribute" "$@"
	done
}

# Install Grunt plugins and add them as `devDependencies` to `package.json`
# Usage: `gi contrib-watch contrib-uglify zopfli`
function gi() {
	local IFS=,
	eval npm install --save-dev grunt-{"$*"}
}

# `m` with no arguments opens the current directory in TextMate, otherwise
# opens the given location
function m() {
	if [ $# -eq 0 ]; then
		mate .
	else
		mate "$@"
	fi
}

# `s` with no arguments opens the current directory in Sublime Text, otherwise
# opens the given location
function s() {
	if [ $# -eq 0 ]; then
		subl .
	else
		subl "$@"
	fi
}

# `v` with no arguments opens the current directory in Vim, otherwise opens the
# given location
function v() {
	if [ $# -eq 0 ]; then
		vim .
	else
		vim "$@"
	fi
}

# `o` with no arguments opens current directory, otherwise opens the given
# location
function o() {
	if [ $# -eq 0 ]; then
		open .
	else
		open "$@"
	fi
}

# `np` with an optional argument `patch`/`minor`/`major`/`<version>`
# defaults to `patch`
function np() {
	git pull --rebase && \
	npm install && \
	npm test && \
	npm version ${1:=patch} && \
	npm publish && \
	git push origin master && \
	git push origin master --tags
}

# `tre` is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
function tre() {
	tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX
}

function vnc() {
	open "vnc://$1.silvertailsystems.com:5901"
}
display() {
    export DISPLAY=`vncserver -list |tail -n +5 | sed -e 's/^\(:[0-9]\+\).*$/\1/'`;
}
 
startvnc() {
    servers=`/usr/bin/vncserver -list | tail -n+5 | wc -l`
    if [[ "$servers" -eq 0 ]]; then
        /usr/bin/vncserver -geometry 1440x900
    fi
    
    servers=`/usr/bin/vncserver -list | tail -n+5 | wc -l`
    if [[ "$servers" -ne 0 ]]; then
        vnc_display=`vncserver -list | tail -n +5 | sed -e 's/^\(\S\+\).*$/localhost\1.0/'`
        export OLDDISPLAY=${DISPLAY}
        export DISPLAY=$vnc_display
        vnc_port=$(ps ww $(vncserver -list |tail -n +5 | sed -e s/^\\S\\+\\s\\+//) | tail -n +2 | sed -e s/^.*-rfbport\ // -e s/\\s.*$//)
        echo "Set display to $DISPLAY"
        echo "Connect your vnc session to: ${HOSTNAME}:${vnc_port}"
    else
        echo "The vncserver failed to start"
    fi
}
  
stopvnc() {
    echo "Stopping vnc server on current display..."
    servers=`/usr/bin/vncserver -list | tail -n+5 | wc -l`
    echo "Found $servers active servers"
    if [[ "$servers" -ne 0 ]]; then
        echo "Want to kill ${DISPLAY#localhost}"
        vncserver -kill ${DISPLAY#localhost}
        export DISPLAY=${OLDDISPLAY}
        echo "Now display is ${DISPLAY}"
        rm -vf ~/.vnc/*.{log,pid}
    fi
}
   
# Toggle WUI_HEADLESS between true, and unset
# -l argument just prints the current value
headless() {
    if [ ! "$1" = "-l" ]; then
        if [ -z "$WUI_HEADLESS" ]; then
            export WUI_HEADLESS=true
       else
            unset WUI_HEADLESS
       fi
    fi
    msg="WUI_HEADLESS = $WUI_HEADLESS"
    if [ -z "$WUI_HEADLESS" ]; then
        msg="$msg<unset>"
    fi
    echo "$msg"
}
    
# remote allows you to unset (-d), show (-l), set to current host (no arg), or
# set to a remote host (any qualified or unqualified host name) WUI_VM_NAME
remote() {
    if [ "$1" = "-d" ]; then
        unset WUI_VM_NAME
    else
        if [ ! "$1" = "-l" ]; then
            if [ -z "$1" ]; then
                vm=$(uname -n)
            else
                vm=$1
            fi
            # keep the hostname entered only to the first "."
            export WUI_VM_NAME=${vm%%.*}
        fi
     fi
     echo WUI_VM_NAME=${WUI_VM_NAME}
}

function search {
    find . \( -name "*.cpp" -o -name "*.h" \) | xargs grep -n "$1"
}

function searchpy {
    find . \( -name "*.py" \) | xargs grep -n "$1"
}

function de {
    (cd ./o && less +F `find .|grep "$@"|xargs ls -arth|tail -1`)
}

function gbackout {
        git reset HEAD $1 ; git co -- $1
}

function noseloop() { while true; do touch test/*.py ; nosetests "$@" ; if [ $? != 0 ]; then break; fi;  done }
function bldloop() { while true; do touch test/*.py ; bld "$@" ; if [ $? != 0 ]; then break; fi;  done }

netinfo ()
{
echo "--------------- Network Information ---------------"
/sbin/ifconfig | awk /'inet addr/ {print $2}'
echo ""
/sbin/ifconfig | awk /'Bcast/ {print $3}'
echo ""
/sbin/ifconfig | awk /'inet addr/ {print $4}'

# /sbin/ifconfig | awk /'HWaddr/ {print $4,$5}'
echo "---------------------------------------------------"
}

spin ()
{
echo -ne "${RED}-"
echo -ne "${WHITE}\b|"    
echo -ne "${BLUE}\bx"
sleep .02
echo -ne "${RED}\b+${NC}"
}

# WELCOME SCREEN
#######################################################

clear
#for i in `seq 1 15` ; do spin; done ;echo -ne "${WHITE} USA Linux Users Group ${NC}"; for i in `seq 1 15` ; do spin; done ;echo "";
#echo -e ${LIGHTBLUE}`cat /etc/SuSE-release` ;
#echo -e "Kernel Information: " `uname -smr`;
#echo -e ${LIGHTBLUE}`bash --version`;echo ""
#echo -ne "Hello $USER today is "; date
#echo -e "${WHITE}"; cal ; echo ""; 
#echo -ne "${CYAN}";netinfo;
#mountedinfo ; echo ""
#echo -ne "${LIGHTBLUE}Uptime for this computer is ";uptime | awk /'up/ {print $3,$4}'
#for i in `seq 1 15` ; do spin; done ;echo -ne "${WHITE} http://usalug.org ${NC}"; for i in `seq 1 15` ; do spin; done ;echo "";
#echo ""; echo ""