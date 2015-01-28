#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

source /usr/lib/qubes-whonix/utility_functions


# Files that will have the immutable bit set
# since we don't want them modified by other programs
IMMUTABLE_FILES=(
    '/etc/resolv.conf'
    '/etc/hostname'
    '/etc/hosts'
)


resetGatewayIP() {
    if [ "${QUBES_WHONIX}" == "gateway" ]; then
        echo "10.152.152.10" > /etc/whonix-netvm-gateway
    elif [ "${QUBES_WHONIX}" == "workstation" ]; then
        echo "10.152.152.11" > /etc/whonix-netvm-gateway
    fi
}


# Install default IP address to use in search and replace.
# It gets updated with current IP address as it get updated
if [ ! -e "/etc/whonix-netvm-gateway" ]; then
    resetGatewayIP
fi

# Make sure all .anondist files in list are immutable
immutableFilesEnable "${IMMUTABLE_FILES}"
immutableFilesEnable "${IMMUTABLE_FILES}" ".anondist"

# Make sure we are using a copy of the annondist file and if not
# copy the annondist file and set it immutable
copyAnondist "/etc/resolv.conf"
copyAnondist "/etc/hosts"
copyAnondist "/etc/hostname"

if [ "${QUBES_WHONIX}" == "gateway" ] || [ "${QUBES_WHONIX}" == "workstation" ]; then
    # Replace IP addresses in known configuration files / scripts to
    # currently discovered one
    /usr/lib/qubes-whonix/init/replace-ips

    # Make sure hostname is correct
    /bin/hostname host
fi
