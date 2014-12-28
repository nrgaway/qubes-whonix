#!/bin/bash

. /usr/lib/whonix/utility_functions

if [ -x /usr/sbin/xenstore-read ]; then
    XENSTORE_READ="/usr/sbin/xenstore-read"
else
    XENSTORE_READ="/usr/bin/xenstore-read"
fi

# Make sure IP forwarding is disabled
echo "0" > /proc/sys/net/ipv4/ip_forward

if [ "${WHONIX}" != "template" ]; then
    ip=$(${XENSTORE_READ} qubes-netvm-gateway 2> /dev/null)

    # Start Whonix Firewall
    if [ "${WHONIX}" == "gateway" ]; then
        export INT_IF="vif+"
        export INT_TIF="vif+"

        # Inject custom firewall rules into whonix_firewall
        sed -i -f - /usr/bin/whonix_firewall <<-EOF
/^## IPv4 DROP INVALID INCOMING PACKAGES/,/######################################/c \\
## IPv4 DROP INVALID INCOMING PACKAGES \\
## \\
## --- THE FOLLOWING WS INJECTED --- \\
##     Qubes Tiny Proxy Updater \\
iptables -t nat -N PR-QBS-SERVICES \\
iptables -A INPUT -i vif+ -p tcp -m tcp --dport 8082 -j ACCEPT \\
iptables -A OUTPUT -o vif+ -p tcp -m tcp --sport 8082 -j ACCEPT \\
iptables -t nat -A PREROUTING -j PR-QBS-SERVICES \\
iptables -t nat -A PR-QBS-SERVICES -d 10.137.255.254/32 -i vif+ -p tcp -m tcp --dport 8082 -j REDIRECT \\
iptables -t nat -A OUTPUT -p udp -m owner --uid-owner tinyproxy -m conntrack --ctstate NEW -j DNAT --to ${ip}:53 \\
iptables -t nat -A OUTPUT -p tcp -m owner --uid-owner tinyproxy -m conntrack --ctstate NEW -j DNAT --to ${ip}:9040 \\
\\
# Route any traffic FROM netvm TO netvm BACK-TO localhost \\
# Allows localhost access to tor network \\
#iptables -t nat -A OUTPUT -s ${ip} -d ${ip} -j DNAT --to-destination 127.0.0.1 \\
######################################
EOF
    fi

    # Load the firewall
    # XXX: TODO:  Take down all network accesss if firewall fails
    /usr/bin/whonix_firewall

    systemctl restart qubes-updates-proxy.service
fi
