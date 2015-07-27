#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :
#
# utility_functions.sh - Various utility functions or shared code used by
#                        the 'qubes-whonix' package.
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

export QT_X11_NO_MITSHM=1
export XDG_CURRENT_DESKTOP=gnome

# 'apt-get' proxy server
PROXY_SERVER='http://10.137.255.254:8082/'

# 'tinyproxy' replacement text for 'usr/share/tinyproxy/default.html' which is
# used to determine if the proxy server is a secure Tor proxy server to prevent
# updates over the reqular Qubes firewall VM
PROXY_META='<meta name=\"application-name\" content=\"tor proxy\"\/>'

# QUBESDB and PREFIX are used to access data in Qubes database.  The interfaces
# to the database has changed in Release 3, so these vars will contain the proper
# program and syntax to use when accessing the database.

    # Qubes R3
    if which qubesdb-read > /dev/null; then
        QUBESDB=qubesdb
        PREFIX='/'

    # Qubes R2
    else
        QUBESDB=xenstore
        PREFIX=''
    fi

# Sets provided list of files ($1) appending optional suffix ($2) to immutable
immutableFilesEnable() {
    files="${1}"
    suffix="${2}"

    for file in "${files[@]}"; do
        if [ -f "${file}" ] && ! [ -L "${file}" ]; then
            chattr +i "${file}${suffix}"
        fi
    done
}

# Sets provided list of files ($1) appending optional suffix ($2) to mutable
immutableFilesDisable() {
    files="${1}"
    suffix="${2}"

    for file in "${files[@]}"; do
        if [ -f "${file}" ] && ! [ -L "${file}" ]; then
            chattr -i "${file}${suffix}"
        fi
    done
}

# Copies provided list of anondist files ($1)+suffix($2) to original filename.
#
# Example:
#  $1 = '/etc/resolv.conf'
#  $2 = '.anondist'
#
#  1. If softlink exists with the name of '/etc/resolv.conf', it is deleted
#  2. If a regular file with the name of '/etc/resolv.conf' exists AND
#     the file differs from the anondist file '/etc/resolv.conf.anondist',
#     '/etc/resolv.conf' will be deleted and '/etc/resolv.conf.anondist' will
#     be copied to '/etc/resolv.conf':
#       cp '/etc/resolv.conf.anondist' '/etc/resolv.conf'
#  3. If the regular file '/etc/resolv.conf' does not exist, it will copy the
#     anondist file to it's location as shown in step 2 above.
copyAnondist() {
    file="${1}"
    suffix="${2-.anondist}"

    # Remove any softlinks first
    if [ -L "${file}" ]; then
        rm -f "${file}"
    fi

    if [ -f "${file}" ] && [ -n "$(diff ${file} ${file}${suffix})" ]; then
        chattr -i "${file}"
        rm -f "${file}"
        cp -p "${file}${suffix}" "${file}"
    elif ! [ -f "${file}" ]; then
        cp -p "${file}${suffix}" "${file}"
    fi
}

# Change a systemd file to either enabled or disabled.
#
# Will stop any active processes when disabling and forcibly disable certain
# types of unit files that do not have an '[Install]' section.
changeSystemdStatus() {
    unit=${1}
    disable=${2-0}

    # Check if unit file is currently active (running)
    systemctl is-active ${unit} > /dev/null 2>&1 && active=true || unset active

    case ${disable} in
        0)
            systemctl --quiet enable ${unit} > /dev/null 2>&1 || true
            ;;
        1)
            if [ ${active} ]; then
                systemctl --quiet stop ${unit} > /dev/null 2>&1 || true
            fi

            if [ -f /lib/systemd/system/${unit} ]; then
                if fgrep -q '[Install]' /lib/systemd/system/${unit}; then
                    systemctl --quiet disable ${unit} > /dev/null 2>&1 || true
                else
                    # Forcibly disable
                    ln -sf /dev/null /etc/systemd/system/${unit}
                fi
            else
                systemctl --quiet disable ${unit} > /dev/null 2>&1 || true
            fi
            ;;
    esac
}

# Wrapper to enable a sysv service
enable_sysv() {
    changeSystemdStatus ${1} 0
}

# Wrapper to disable a sysv service
disable_sysv() {
    changeSystemdStatus ${1} 1
}
