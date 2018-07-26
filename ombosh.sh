#!/bin/bash

OM_COMMAND=om
OM_USER="admin"
OM_PASSWORD=""
OM_KEY=""

function usage {
  echo "ombosh.sh - Set BOSH environment variables to tunnel through Ops Manager"
  echo
  echo "Usage: source ombosh.sh [flags...]"
  echo "  -c, --om-command     Override the om CLI command (deafult 'om')"
  echo "  -t, --om-target      Target the specified Ops Manager VM"
  echo "  -u, --om-user        Override the Ops Manager user (default 'admin')"
  echo "  -p, --om-password    Specify the Ops Manager password"
  echo "  -i, --private-key    The private key for SSH into Ops Manager VM"
  echo "  -h, --help           Show this help message"
  echo
}

# while (( "$#" )); do
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h | --help )
      usage
      exit 0
      ;;
    -c | --om-command )
      OM_COMMAND="$2"
      shift 2
      ;;
    -t | --om-target )
      OM_HOST="$2"
      shift 2
      ;;
    -u | --om-user )
      OM_USER="$2"
      shift 2
      ;;
    -p | --om-password )
      OM_PASSWORD="$2"
      shift 2
      ;;
    -i | --private-key )
      OM_KEY="$2"
      shift 2
      ;;
    -* | --*= )
      echo "Error: unsupported option $1" >&2
      exit 1
      ;;
  esac
done

# prompt for missing fields
# note: intentionally not using read's -p option for the prompt,
# as this works on bash but not on zsh
if [ -z $OM_HOST ]; then
  echo "Ops Manager Hostname:"
  read OM_HOST
fi
if [ -z $OM_PASSWORD ]; then
  echo "Ops Manager Password:"
  read -s OM_PASSWORD
fi
if [ -z $OM_KEY ]; then
  echo "Path to SSH private key for OM:"
  read -s OM_KEY
fi
echo

if [ ! -f $OM_KEY ]; then
  echo "Private key file $OM_KEY does not exist" >&2
  exit 1
fi

function omc {
  $OM_COMMAND --target https://$OM_HOST --skip-ssl-validation --username $OM_USER --password $OM_PASSWORD "$@"
}

# get BOSH command line credentials from ops manager
CREDS=$(omc curl --silent \
     -p /api/v0/deployed/director/credentials/bosh_commandline_credentials | \
  jq -r .credential | sed 's/bosh //g')

# this will set BOSH_CLIENT, BOSH_ENVIRONMENT, BOSH_CLIENT_SECRET, and BOSH_CA_CERT
# however, BOSH_CA_CERT will be a path that is only valid on the OM VM
[ -n "${ZSH_VERSION}" ] && setopt shwordsplit
array=($CREDS)
for VAR in ${array[@]}; do
  export $VAR
done
[ -n "${ZSH_VERSION}" ] && unsetopt shwordsplit

# fetch the contents of the CA cert
export BOSH_CA_CERT="$(omc certificate-authorities -f json | \
    jq -r '.[] | select(.active==true) | .cert_pem')"

export BOSH_ALL_PROXY="ssh+socks5://ubuntu@$OM_HOST:22?private-key=$OM_KEY"
