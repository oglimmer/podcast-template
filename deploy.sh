#!/bin/bash

# 1st param: separator
# from 2nd param: key-value pairs like "key":value
function createJsonFromArray
{ 
	local IFS="$1"
	shift
	echo '{'"$*"'}'
}
declare -a EXTRA_VARS=() 

#     -d  deploy or re-deploy if necessary IS DEFAULT

usage="$(basename "$0") [-c] [-v] [-n] [-u] environment target - super setup script

where:
    -h  shows this help text
    -c  clean temporary files
    -n  do not resolve dependencies
    -u  update apt cache
    -v  verbose"

cd ${0%/*}

while getopts ':hcvnu' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    c) echo "Clean..."
       EXTRA_VARS+=('"cleanTemporaryFiles": true')
       ;;
    v) VERBOSE="-vvvv"
       ;;
    n) echo "Skipping dependencies..."
       EXTRA_VARS+=('"noDependencies": true')
     ;;
    u) echo "Update apt cache..."
       EXTRA_VARS+=('"apt_update_cache": true')
     ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

ENVIRONMENT=$1
TARGET=$2

if [ -n "$ENVIRONMENT" ] && [ -n "$TARGET" ]; then
	echo "Preparing ansible run"
  echo "ENVIRONMENT=$ENVIRONMENT - TARGET=$TARGET"

	if [ "$ENVIRONMENT" = "staging" ]; then
		# prepare insecure ssh
		rm -f /tmp/vagrant.key 
		curl --silent https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant >/tmp/vagrant.key		              
		chmod 400 /tmp/vagrant.key 
		export ANSIBLE_HOST_KEY_CHECKING=False
		SSHUSER=ubuntu
		SUDO="--sudo"
		SSHKEY="--private-key=/tmp/vagrant.key"
	else 
		SSHUSER=root
	fi

	EXTRA_VARS_JSON=$(createJsonFromArray , "${EXTRA_VARS[@]}")
	# provision
	echo "ansible-playbook $TARGET.yml --user=$SSHUSER $SUDO --timeout=100 --inventory-file=$ENVIRONMENT/inventory.ini $SSHKEY --extra-vars=$EXTRA_VARS_JSON $VERBOSE"
	ansible-playbook $TARGET.yml --user=$SSHUSER $SUDO --timeout=100 --inventory-file=$ENVIRONMENT/inventory.ini $SSHKEY --extra-vars="$EXTRA_VARS_JSON" $VERBOSE
else
    echo "$usage" >&2
fi
