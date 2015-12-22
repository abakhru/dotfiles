#!/bin/bash
# General tools for bash scripts

# rellink checks for a relative link and creates a complete path for it
rellink () {
    fn=$1
    targ=$2
    while [[ "${targ:0:3}" == "../" ]]; do
        targ=${targ:3}
        fn=`dirname $fn`
    done
    echo $(dirname $fn)/$targ
}


# Path Add command adds an element to the path only if it is not already in the path
path_add () {
    if [[ ":${PATH}:" != *":${1}:"* ]]; then
        if [[ "$2" != "" ]]; then
            export PATH="${PATH}:${1}";
        else
            export PATH="${1}:${PATH}";
        fi;
    fi
}

# path_remove removes the path element from the path
path_remove () {
    newpath=
    if [[ ":${PATH}:" == *":${1}:"* ]]; then
        for pel in `echo ${PATH} | sed -e 's/:/ /g'`; do
            if [[ "$pel" != "${1}" ]]; then
                if [[ "$newpath" == "" ]]; then
                    newpath="${pel}"
                else
                    newpath="${newpath}:${pel}"
                fi
            fi
        done
        export PATH=${newpath}
    else
        echo "The path element ${1} does not exist in path ${PATH}"
    fi
}
alias pathrm=path_remove

# path_update If the new path element doesn't exist, then add it, if it does, put it at beginning or end
# If the second argument exists, move or add to the end - depends on path_remove and path_add
path_update () {
    export OLDPATH=$PATH
    if [[ ":${PATH}:" == *":${1}:"* ]]; then
        path_remove "${1}"
    fi
    if [[ "${2}" != "" ]]; then
        path_add "${1}" end
    else
        path_add "${1}"
    fi
}

unset_java() {
    if [[ ${OLD_PATH+x} ]]; then
        export PATH=$OLD_PATH
        unset OLD_PATH
    fi
    if [[ ${OLD_JAVA_HOME+x} ]]; then
        export JAVA_HOME=$OLD_JAVA_HOME
        unset OLD_JAVA_HOME
    fi
}

set_java() {
    unset_java
    export OLD_PATH=$PATH
    export OLD_JAVA_HOME=$JAVA_HOME
    jpath=$(dirname $(/usr/sbin/alternatives --display javac | egrep "${1}.*priority" | awk '{print $1}' | head -1))
    path_update ${jpath}
    export JAVA_HOME=$(dirname ${jpath})
}

is_defined() {
    type ${1} > /dev/null 2>&1
}

defined () {
    is_defined ${1}
    if [ "$?" == "0" ]; then
        echo "Bash function ${1} is defined"
    else
        echo "Bash function ${1} is not defined"
    fi
}
