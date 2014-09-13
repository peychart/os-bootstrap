Overview
========

  openstack.gov.pf bootstrap (can be executed multiple times).

  Allows to create the first server (gitlab & repository) of the openstack.gov.pf plateform. The second will be the chef-server (see http://gitlab.os.gov.pf/root/chef/tree/master).

  Once these two servers are built, the production environment exists and allows to create all the other nodes from the recipes and roles presents in the chef server and to live and evolve these tools through the gitlab server.

  The repository sites allows meanwhile to keep available, where it is needed, all the backups and packages to deal with any incident of production, in optimal efficiency and safety conditions.


Topic
=====

 Create the first openstack server providing the following services:
 - gitlab,
 - repository,
 - the backup nodes for the cloud bare metal.


Organisation
============

The main assumption is that it always persists somewhere a swift operational services containing all the IT assets of the Polynesian administration.


Everything -about the data center to (re)built- will be create from the access to this swift service:
 - from curl commands in a first time,
 - from the cloudfuse service in a second time,
 - and, ultimately, from the http service, through the repository service accessing the cloudfuse resource previously implemented, 

The cloudfuse resources (swift containers) are:
 - os-bootstrap: containing the first (shell) recipes,
 - os-backup: containing all the backups
 - repository: the root of the repository service - containning all the archives and images.


Dependencies
============

 - The gitlab service needs "postfix" and "cloudfuse" (to ensure data recovery),
 - The repository service needs a "nginx" server (already installed with gitlab) and "cloudfuse" as storage space.
 - The backups of the cisco devices need the "tftp" service, the "crontab" service and the "cloudfuse" service as storage space.


HOWTO
=====

$ #!/bin/bash

- Make a node:

    eg (on vsphere):

        sudo apt-get install python-pip

        sudo pip install ezmomi

        ezmomi clone --hostname acronix --domain os.gov.pf --ips 172.16.192.4 10.10.0.4 --cpus 2 --mem 1

- connect:   ssh root@node,
- set the IP(s) address(es) of the node (pending to choose an alternative to knife-sphere)

$ # Verify the curl command:

$ ! command -v curl && echo "curl install..." && apt-get install curl -y --force-yes >/tmp/install-curl.log 2>&1 #
$ 

$ # Verify the swift ipaddress from the file "/etc/hosts":

$ grep -Pv "^[ \t]*#" /etc/hosts| grep -qsw swiftauth || (echo; echo "10.10.0.30      swiftauth.os.gov.pf swiftauth") >> /etc/hosts #
$ 

$ # Get your X-Auth-Token and the X_Storage_Url:

- eg.:

             export X_Auth_Token= *Your_X-Auth-Token*
             export X_Storage_Url= *Your_X_Storage_Url*
          with:
             curl -is -H "X-Auth-User: system:root" -H "X-Auth-Key: testpass" http://swiftauth:8080/auth/v1.0

- or, execute:

$ $( curl -is -H "X-Auth-User: system:root" -H "X-Auth-Key: testpass" http://swiftauth:8080/auth/v1.0| grep -e "^X-Auth-Token: " -e "^X-Storage-Url: "| sed -e 's/^X-Auth-Token: /export X_Auth_Token=/' -e 's/^X-Storage-Url: /export X_Storage_Url=/' -e 's/\r$//' ) #
$ 

$ # Then, launch the bootstrap (or any other install-*service_name*.sh file):

        syntaxe:  curl -sfH "X-Auth-Token: *Your_X-Auth-Token*" \
                       *Your_X_Storage_Url*/os-bootstrap/start-install.sh \
                           | bash -s -- -t *Your_X-Auth-Token* *Your_X_Storage_Url* \
                                        [ *--service_name* "*service_argument1* *service_argument2* ..." ] \

                                        [ *--service_name2* ... ] \

                                        [ ... ]

                  To see the possibles services arguments: curl -sfH "X-Auth-Token: $X_Auth_Token" \
                                                                $X_Storage_Url/os-bootstrap/install-*service_name*.sh \
                                                                | bash -s -- -h

- eg.:

$ curl -sfH "X-Auth-Token: $X_Auth_Token" $X_Storage_Url/os-bootstrap/start-install.sh| bash -s -- $* 2>/tmp/errlog| tee /tmp/log; cat /tmp/errlog

        or:  curl -sfH "X-Auth-Token: $X_Auth_Token" $X_Storage_Url/os-bootstrap/start-install.sh \
             | bash -s -- -s "crontab bootstrap hostname cloudfuse postfix gitlab repository tftp proxyapt doc ip" \
                          -t $X_Auth_Token \
                          --hostname acronix.toriki.os.gov.pf \
                          --cloudfuse https://github.com/redbo/cloudfuse.git \
                          --doc "doc.os.gov.pf \
                                 -d /media/cloudfuse/os-documentation/ \
                                 -s /var/opt/gitlab/git-data/gitlab-satellites/root/os-documentation/" \
                          $X_Storage_Url

        or, for help:
             curl -sfH "X-Auth-Token: $X_Auth_Token" $X_Storage_Url/os-bootstrap/install-repository.sh | bash -s -- -h

        This readme:
             curl -sfH "X-Auth-Token: $X_Auth_Token" $X_Storage_Url/os-bootstrap/README.rd


SHELL SCRIPT
============

The command to extract a shell script (cf jenkins) from this README.md is:

     curl -sfL "https://raw.githubusercontent.com/peychart/os-bootstrap/master/README.md"| grep "^\$ "| sed -e 's/^\$ //'

