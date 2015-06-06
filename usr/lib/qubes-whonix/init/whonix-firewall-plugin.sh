#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :
#
# whonix-firewall-plugin.sh - Provides additional 'Whonix_firewall' rules.
#
# Included by whonix_firewall configurations located at:
#   /etc/whonix_firewall.d/40_qubes
#
# This file is part of Qubes+Whonix.
# Copyright (C) 2014 - 2015 Jason Mehring <nrgaway@gmail.com>
# License: GPL-2+
# Authors: Jason Mehring
#
#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation; either version 2
#   of the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

source /usr/lib/qubes-whonix/utility_functions.sh

# Start Whonix Firewall
if [ -e /var/run/qubes-service/whonix-gateway ]; then
    ip=$(${QUBESDB}-read ${PREFIX}qubes-netvm-gateway 2> /dev/null)

    export INT_IF="vif+"
    export INT_TIF="vif+"

    # Allow connections from port 8082 of internal vif interface for tinyproxy
    # tinyproxy is responsible to handle TemplateVMs updates
    iptables --wait -A INPUT -i vif+ -p tcp -m tcp --dport 8082 -j ACCEPT
    iptables --wait -A OUTPUT -o vif+ -p tcp -m tcp --sport 8082 -j ACCEPT

    # Qubes pre-routing. Will be able to intercept traffic destined for
    # 10.137.255.254 to be re-routed to tinyproxy
    iptables --wait -t nat -N PR-QBS-SERVICES
    iptables --wait -t nat -A PREROUTING -j PR-QBS-SERVICES

    # Redirects traffic destined for 10.137.255.154 to port 8082 (tinyproxy)
    iptables --wait -t nat -A PR-QBS-SERVICES -d 10.137.255.254/32 -i vif+ -p tcp -m tcp --dport 8082 -j REDIRECT

    # Forward tinyproxy output to port 53/9040 on internal (Tor) interface (eth1) to be
    # able to connect to Internet (via Tor) to proxy updates for TemplateVM
    iptables --wait -t nat -A OUTPUT -p udp -m owner --uid-owner tinyproxy -m conntrack --ctstate NEW -j DNAT --to ${ip}:53
    iptables --wait -t nat -A OUTPUT -p tcp -m owner --uid-owner tinyproxy -m conntrack --ctstate NEW -j DNAT --to ${ip}:9040
fi

if [ -e /var/run/qubes-service/whonix-template ]; then

    # Allow access to qubes update proxy
    iptables --wait -A OUTPUT -o eth0 -p tcp -m tcp --dport 8082 -j ACCEPT
fi
