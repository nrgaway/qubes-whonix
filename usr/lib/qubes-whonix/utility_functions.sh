#!/bin/bash -e
# vim: set ts=4 sw=4 sts=4 et :

export QT_X11_NO_MITSHM=1
export XDG_CURRENT_DESKTOP=gnome

# /etc/uwt.d/40_qubes relies on 'whonix-secure-proxy' being
# available to enable apt-get
PROXY_SERVER='http://10.137.255.254:8082/'
PROXY_META='<meta name=\"application-name\" content=\"tor proxy\"\/>'

# Qubes R3
if which qubesdb-read > /dev/null; then
    QUBESDB=qubesdb
    PREFIX='/'

# Qubes R2
else
    QUBESDB=xenstore
    PREFIX=''
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
