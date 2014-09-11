#!/bin/bash
# set the hostname on a standard node
#PE-20140707
SERVICE=bootstrap
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

# Analyse des arguments:
while getopts h opt
do case "$opt" in
    h|\?) #unknown flag
       printhlp "syntaxe: $MYNAME <services_list>"
       printhlp
       printhlp "eg.   curl -sfH \"X-Auth-Token: <X_Auth_Token>\" \\"
       printhlp "           http://swiftauth:8080/v1/AUTH_system/os-bootstrap/$MYNAME \\"
       printhlp "        | bash -s -- <services_list>"
       printhlp
       printhlp "from: curl -is -H \"X-Auth-User: system:root\" \\"
       printhlp "               -H \"X-Auth-Key: testpass\" \\"
       printhlp "               http://swiftauth:8080/auth/v1.0"
       printhlp
       exit 0;;
esac done
shift `expr $OPTIND - 1`
! whoami | grep -qsw root && printerr "must be root to do that..." >&2 && exit 1

# set the crontab file:
! curl -sfH "X-Auth-Token: $X_Auth_Token" $X_Storage_Url/os-bootstrap/install-crontab| bash \
 && printerr "cron config failed (procedure aborted)..." && exit 1

if ! crontab -l| grep -qs "^[^#].*for i in $*;"; then
 (comment="# os-bootstrap backup on swift:"
  crontab -l| grep -v "/os-bootstrap/"| grep -v "$comment"
     echo "$comment"
     echo '30 0 * * *   curl -sfL http://gitlab.os.gov.pf/root/bootstrap/raw/master/README.md >/tmp/.mycrontab.$$ && [ -s /tmp/.mycrontab.$$ ] && mv -f /tmp/.mycrontab.$$ /media/cloudfuse/os-bootstrap/README.md 2>/dev/null'
     echo '31 0 * * *   curl -sfL http://gitlab.os.gov.pf/root/bootstrap/raw/master/start-install.sh >/tmp/.mycrontab.$$ && [ -s /tmp/.mycrontab.$$ ] && mv -f /tmp/.mycrontab.$$ /media/cloudfuse/os-bootstrap/start-install.sh 2>/dev/null'
     echo '32 0 * * *   for i in '$*'; do curl -sfL http://gitlab.os.gov.pf/root/bootstrap/raw/master/install-$i.sh >/tmp/.mycrontab.$$ && [ -s /tmp/.mycrontab.$$ ] && mv -f /tmp/.mycrontab.$$ /media/cloudfuse/os-bootstrap/install-$i.sh 2>/dev/null; done'
     echo
  )| crontab -
  printstd "$SERVICE succefully installed."
else
  printwrn "$SERVICE was already configured..."
fi

