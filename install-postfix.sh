#!/bin/bash
# Instalation de postfix à partir d'un node standard
#PE-20140707
SERVICE=postfix
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

domain=${domain:-informatique.gov.pf}

# Analyse des arguments:
while getopts h opt
do case "$opt" in
    h|\?) #unknown flag
       printhlp "syntaxe: $MYNAME <mail.domain.name>"
       printhlp
       printhlp "eg.   $MYNAME informatique.gov.pf"
       printhlp
       printhlp "or:   curl -sfH \"X-Auth-Token: <X_Auth_Token>\" \\"
       printhlp "           <X-Storage-Url>/os-bootstrap/$MYNAME \\"
       printhlp "        | bash -s -- informatique.gov.pf"
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


# install postfix:
echo "# *********** Generated by the \"apt_get install postfix\" procedure:" >/tmp/$MYNAME.log
! apt-get -q install postfix -y --force-yes >>/tmp/$MYNAME.log 2>&1 \
  && printerr "postfix install error (see: /tmp/$MYNAME.log)..." && exit 1
if ! grep -qsw $domain /etc/postfix/mailname; then
  cat >/etc/postfix/mailname <<@@@
$domain
@@@
  printstd "$SERVICE is succefully configured..."
  /etc/init.d/postfix stop
  /etc/init.d/postfix start
else
  printwrn "$SERVICE was already configured..."
fi


# Do the iptable rules:
CONFile=/etc/iptables.d/filter/INPUT/$SERVICE
mkdir -p $(dirname $CONFile); cat >$CONFile <<@@@
# Dynamic file generated by chef
#     DO NOT EDIT THIS FILE BY HAND -- YOUR CHANGES WILL BE OVERWRITTEN
--append INPUT INPUT --protocol tcp --dport 25 --sport 1024:65535 --match state --state NEW --jump ACCEPT
@@@

