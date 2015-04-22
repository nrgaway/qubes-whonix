#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

export QT_X11_NO_MITSHM=1
export XDG_CURRENT_DESKTOP=gnome

# /etc/uwt.d/50_uwt_default relies on this in order to allow connection 
# to proxy for template
PROXY_SERVER="http://10.137.255.254:8082/"
PROXY_META='<meta name=\"application-name\" content=\"tor proxy\"\/>'

if [ ! -d "/var/run/qubes" ]; then
    QUBES_WHONIX="unknown"
    exit 0

elif [ -f "/var/run/qubes-service/updates-proxy-setup" ]; then
    QUBES_WHONIX="template"
    if [ ! -e '/var/run/qubes-service/qubes-whonix-secure-proxy' ]; then
        curl.anondist-orig --connect-timeout 3 "${PROXY_SERVER}" | grep -q "${PROXY_META}" && {
            sudo touch '/var/run/qubes-service/qubes-whonix-secure-proxy'
        }
    fi

elif [ -f "/usr/share/anon-gw-base-files/gateway" ]; then
    QUBES_WHONIX="gateway"

elif [ -f "/usr/share/anon-ws-base-files/workstation" ]; then
    QUBES_WHONIX="workstation"

else
    QUBES_WHONIX="unknown"
fi

immutableFilesEnable() {
    files="${1}"
    suffix="${2}"

    for file in "${files[@]}"; do
        if [ -f "${file}" ] && ! [ -L "${file}" ]; then 
            sudo chattr +i "${file}${suffix}"
        fi
    done
}

immutableFilesDisable() {
    files="${1}"
    suffix="${2}"

    for file in "${files[@]}"; do
        if [ -f "${file}" ] && ! [ -L "${file}" ]; then 
            sudo chattr -i "${file}${suffix}"
        fi
    done
}

copyAnondist() {
    file="${1}"
    suffix="${2-.anondist}"

    # Remove any softlinks first
    if [ -L "${file}" ]; then 
        sudo rm -f "${file}"
    fi

    if [ -f "${file}" ] && [ -n "$(diff ${file} ${file}${suffix})" ]; then 
        sudo chattr -i "${file}"
        sudo rm -f "${file}"
        sudo cp -p "${file}${suffix}" "${file}"
    elif ! [ -f "${file}" ]; then 
        sudo cp -p "${file}${suffix}" "${file}"
    fi
}

changeSystemdStatus() {
    unit=${1}
    disable=${2-0}
    
    # Check if unit file is currently active (running)
    systemctl is-active ${unit} > /dev/null 2>&1 && active=true || unset active

    case ${disable} in
        0)
            sudo systemctl --quiet enable ${unit} > /dev/null 2>&1 || true
            ;;
        1)  
            if [ $active ]; then
                sudo systemctl --quiet stop ${unit} > /dev/null 2>&1 || true
            fi  

            if [ -f /lib/systemd/system/${unit} ]; then
                if fgrep -q '[Install]' /lib/systemd/system/${unit}; then
                    sudo systemctl --quiet disable ${unit} > /dev/null 2>&1 || true
                else
                    # Forcibly disable
                    sudo ln -sf /dev/null /etc/systemd/system/${unit}
                fi
            else
                sudo systemctl --quiet disable ${unit} > /dev/null 2>&1 || true
            fi
            ;;
    esac
}

enable_sysv() {
    changeSystemdStatus ${1} 0
}

disable_sysv() {
    changeSystemdStatus ${1} 1
}
