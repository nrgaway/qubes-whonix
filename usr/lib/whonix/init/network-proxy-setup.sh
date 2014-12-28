#!/bin/bash

. /usr/lib/whonix/utility_functions

INTERFACE="eth1"

if [ "${WHONIX}" == "gateway" ]; then

    if [ -x /usr/sbin/xenstore-read ]; then
        XENSTORE_READ="/usr/sbin/xenstore-read"
    else
        XENSTORE_READ="/usr/bin/xenstore-read"
    fi

    # Setup Xen / Qubes proxy
    network=$(xenstore-read qubes-netvm-network 2>/dev/null)
    if [ "x$network" != "x" ]; then
        gateway=$(xenstore-read qubes-netvm-gateway)
        netmask=$(xenstore-read qubes-netvm-netmask)
        secondary_dns=$(xenstore-read qubes-netvm-secondary-dns)
        modprobe netbk 2> /dev/null || modprobe xen-netback
        echo "NS1=$gateway" > /var/run/qubes/qubes-ns
        echo "NS2=$secondary_dns" >> /var/run/qubes/qubes-ns
        #/usr/lib/qubes/qubes-setup-dnat-to-ns
        echo "0" > /proc/sys/net/ipv4/ip_forward
        /sbin/ethtool -K eth0 sg off || :
    fi

    # Now, assign it the netvm-gateway IP address
    ip=$(${XENSTORE_READ} qubes-netvm-gateway 2> /dev/null)
    if [ x${ip} != x ]; then
        # Create a dummy eth1 interface so tor can bind to it if there
        # are no DOMU virtual machines connected at the moment
        /sbin/ip link add ${INTERFACE} type dummy

        netmask=$(${XENSTORE_READ} qubes-netvm-netmask)
        gateway=$(${XENSTORE_READ} qubes-netvm-gateway)
        /sbin/ifconfig ${INTERFACE} ${ip} netmask 255.255.255.255
        /sbin/ifconfig ${INTERFACE} up
        /sbin/ethtool -K ${INTERFACE} sg off || true
        /sbin/ethtool -K ${INTERFACE} tx off || true

        ip link set ${INTERFACE} up
    fi

    echo "0" > /proc/sys/net/ipv4/ip_forward

    # Allow whonix-gateway to act as an update-proxy
    touch /var/run/qubes-service/qubes-updates-proxy

    # Search and replace tinyproxy error files so we can inject code that
    # we can use to identify that its a tor proxy so updates are secure
    error_file="/usr/share/tinyproxy/default.html"
    grep -q "${PROXY_META}" "${error_file}" || {
        sed -i "s/<\/head>/${PROXY_META}\n<\/head>/" "${error_file}"
    }
fi
