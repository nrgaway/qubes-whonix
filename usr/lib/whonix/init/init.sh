#!/bin/bash

. /usr/lib/whonix/utility_functions

if [ "${WHONIX}" != "template" ]; then
    # Files that will have the immutable bit set 
    # since we don't want them modified by other programs
    IMMUTABLE_FILES=( 
        '/etc/resolv.conf'
        '/etc/hostname'
        '/etc/hosts'
    )

    # Make sure all .anondist files in list are immutable
    immutableFilesEnable "${IMMUTABLE_FILES}"
    immutableFilesEnable "${IMMUTABLE_FILES}" ".anondist"

    # Make sure we are using a copy of the annondist file and if not
    # copy the annondist file and set it immutable
    copyAnondist "/etc/resolv.conf"
    copyAnondist "/etc/hosts"
    copyAnondist "/etc/hostname"

    # Replace IP addresses in known configuration files / scripts to 
    # currently discovered one
    /usr/lib/whonix/init/replace-ips

    # Make sure hostname is correct
    /bin/hostname host
fi
