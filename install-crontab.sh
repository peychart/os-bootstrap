#!/bin/bash
# set the hostname on a standard node
#PE-20140707
SERVICE=crontab
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
       printhlp "syntaxe: $MYNAME"
       printhlp
       printhlp "eg.   curl -sfH \"X-Auth-Token: <X_Auth_Token>\" \\"
       printhlp "           <X-Storage-Url>/os-bootstrap/$MYNAME \\"
       printhlp "        | bash"
       printhlp
       printhlp "from: curl -is -H \"X-Auth-User: system:root\" \\"
       printhlp "               -H \"X-Auth-Key: testpass\" \\"
       printhlp "               http://swiftauth:8080/auth/v1.0"
       printhlp
       exit 0;;
esac done
shift `expr $OPTIND - 1`
! whoami | grep -qsw root && printerr "must be root to do that..." >&2 && exit 1
[ $# -ne 0 ] && printerr "bad argument... (see: -h)" >&2 && exit 1

# set the crontab file:
if [ 0$(crontab -l 2>/dev/null| wc -l) -eq 0 ]; then
 cat <<@@@ | crontab -
# Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').# 
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
# 
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
# 
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
# 
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command

@@@
 printstd "$SERVICE succefully installed."
else
 printwrn "$SERVICE was already installed."
fi

