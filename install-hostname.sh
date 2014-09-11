#!/bin/bash
# set the hostname on a standard node
#PE-20140707
SERVICE=hostname
MYNAME=${MYNAME:-install-$SERVICE.sh}
MYTMP="/tmp/.$MYNAME.$(date +%Y%m%d.%H%M%S)"
trap "rm -f $MYTMP" 0 1 2 3 5
rouge='\e[0;31m'; vert='\e[0;32m'; jaune='\e[1;33m'; bleu='\e[0;34m'; neutre='\e[0;m';
print() { color=$1; shift; if [ _$(basename $SHELL) = "_bash" ]; then echo -e "${color}$* ${neutre}"; else echo "$*"; fi; }
printstd() { print "${vert}" "$MYNAME: $*"; }
printerr() { print "${rouge}" "$MYNAME: $*" 2>&1; }
printwrn() { print "${jaune}" "$MYNAME: $*"; }
printhlp() { print "${bleu}" "$*"; }
export DEBIAN_FRONTEND=noninteractive

domain=${domain:-acronix.toriki.os.gov.pf}

# Analyse des arguments:
while getopts h opt
do case "$opt" in
    h|\?) #unknown flag
       printhlp "syntaxe: $MYNAME <fqdn>"
       printhlp
       printhlp "eg.   curl -sfH \"X-Auth-Token: <X_Auth_Token>\" \\"
       printhlp "           http://swiftauth:8080/v1/AUTH_system/os-bootstrap/$MYNAME \\"
       printhlp "        | bash -s -- acronix.os.gov.pf"
       printhlp
       printhlp "from: curl -is -H \"X-Auth-User: system:root\" \\"
       printhlp "               -H \"X-Auth-Key: testpass\" \\"
       printhlp "               http://swiftauth:8080/auth/v1.0"
       printhlp
       exit 0;;
esac done
shift `expr $OPTIND - 1`
! whoami | grep -qsw root && printerr "must be root to do that..." && exit 1
[ $# -ne 0 ] && domain=$1 && shift
([ $# -ne 0 ] || ! echo $domain| grep -qs "\.") \
 && printerr "bad argument... (see: -h)" && exit 1

my_first_ip=$(ip addr show dev $(ip route list match 0.0.0.0 | awk 'NR==1 {print $5}') | awk 'NR==3 {print $2}' | cut -d '/' -f1)
[ -z "$my_first_ip" ] \
 && printerr "cannot find my ip (procedure aborted)..." && exit 1

archive=/etc/hosts.$(date +%Y%m%d.%H%M%S)
while [ -f $archive ]; do archive=/etc/hosts.$(date +%Y%m%d.%H%M%S); sleep 1; done
! cp /etc/hosts $archive \
 && printerr "cannot save /etc/hosts (procedure aborted)..." && exit 1


printhlp "$MYNAME: # set the hostname:"
! (echo $(echo $domain| cut -d'.' -f1) >/etc/hostname && hostname $(cat /etc/hostname)) \
 && printerr "cannot change my hostname (procedure aborted)..." && exit 1
printstd "hostname configured."


printhlp "$MYNAME: # set the dnsdomainname:"
if grep -qsw 127.0.1.1 /etc/hosts; then
  sed -e "s/127.0.1.1[ 	].*$/127.0.1.1	$domain $(echo $domain| cut -d'.' -f1)/" <$archive >/etc/hosts
else if grep -qsw $my_first_ip /etc/hosts; then
  sed -e "s/$my_first_ip[ 	].*$/$my_first_ip	$domain $(echo $domain| cut -d'.' -f1)/" <$archive >/etc/hosts
  else
    echo "127.0.1.1	$domain $(echo $domain| cut -d'.' -f1)" >>/etc/hosts
fi fi
printstd "dnsdomainname configured."

printstd "$SERVICE succefully installed."

