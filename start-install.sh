#!/bin/bash
# Instalation du premier noeud openstack.gov.pf à partir d'un system ubuntu-14.04 nu
#PE-20140707

# Tools:
MYNAME=$(basename $0|grep '\.sh$')
MYNAME=${MYNAME:-start-install.sh}
MYTMP="/tmp/.$MYNAME.$(date +%Y%m%d.%H%M%S)"
trap "rm -f $MYTMP" 0 1 2 3 5
rouge='\e[0;31m'; vert='\e[0;32m'; jaune='\e[1;33m'; bleu='\e[0;34m'; neutre='\e[0;m';
print() { color=$1; shift; if [ _$(basename $SHELL) = "_bash" ]; then echo -e "${color}$* ${neutre}"; else echo "$*"; fi; }
printstd() { print "${vert}" "$MYNAME: $*"; }
printerr() { print "${rouge}" "$MYNAME: $*" 2>&1; }
printwrn() { print "${jaune}" "$MYNAME: $*"; }
printhlp() { print "${bleu}" "$*"; }
getopts--() { # Extract the first item "--<pattern> arg" from $*
 OPTARG=""
 local ret=$1 && shift && eval $ret=""
 while [ $# -ne 0 ]; do
  if [ -z "$OPTARG" ] && [ "_$(echo $1| sed -e 's/^\(..\).*/\1/')" = "_--" ]; then
   OPTARG="$(echo $1| sed -e 's/^..//')" && shift
   OPTARG="$OPTARG $(echo $1)" && shift
  else  eval $ret=\"\$$ret \$1\"; shift
  fi
 done
 [ ! -z "$OPTARG" ]
}
export DEBIAN_FRONTEND=noninteractive
# End of tools.


# *****************************************************************************
# main:

# parametres par defaut:
services=${services:-"crontab bootstrap hostname cloudfuse postfix gitlab repository tftp proxyapt doc"}

#   parametres par default des services:
bootstrap=${bootstrap:-"$services"}
gitlab=${gitlab:-"-u gitlab.os.gov.pf -s $X_Storage_Url/repository/archives/ubuntu-14.04/gitlab_7.0.0-omnibus-1_amd64.deb"}


# Analyse des arguments:
while getopts-- others $*; do
  set $OPTARG	# resultat de la premiere extraction de: --<service_name> "<service_argument> ..."
  ! echo $services| grep -qsw $(echo $OPTARG|cut -d' ' -f1) \
   && printerr "bad argument... (see: -h)" && exit 1
  eval $(echo $OPTARG|sed -e 's/ /=/')
  set 0 $others; shift	# restitution des arguments non traités
done
while getopts hs:t: opt
do case "$opt" in
    s) services="$OPTARG";;
    t) X_Auth_Token="$OPTARG";;
    h|\?) #unknown flag
       printhlp "syntaxe: $MYNAME [ -s <services_list> ] -t <X_Auth_Token> <X_Storage_Url> \\"
       printhlp "            [ --<service_name> \"<service_arguments> ...\" ] \\"
       printhlp "            [ --<service_name ... ] \\"
       printhlp "            [ ... ]"
       printhlp
       printhlp "from: curl -is -H \"X-Auth-User: system:root\" \\"
       printhlp "               -H \"X-Auth-Key: testpass\" \\"
       printhlp "               http://swiftauth:8080/auth/v1.0"
       printhlp
       exit 0;;
esac done
shift `expr $OPTIND - 1`
! whoami| grep -qsw root && printerr "must be root to do that..." && exit 1
[ $# -ne 0 ] && X_Storage_Url=$1 && shift
[ $# -ne 0 -o -z "$X_Auth_Token" -o -z "$X_Storage_Url" ] \
  && printerr "bad argument... (see: -h)" && exit 1
export X_Auth_Token X_Storage_Url


# lancement des installations de $services:
# *****************************************************************************
for service in $(echo "$services"| sed -e 's/[,;:|+-]/ /g');  do
  printhlp "# Install service \"$service\":"
  ! curl -sfH "X-Auth-Token: $X_Auth_Token" $X_Storage_Url/os-bootstrap/install-$service.sh| eval bash -s -- \$$service \
    && printerr "Cannot install service, procedure aborted..." \
    && exit 1
done
# *****************************************************************************

