#!/bin/bash

#
# To umount all binds, just pass any arg in $1
#

. /usr/lib/whonix/utility_functions

# Don't run if started as a template
if ! [ "${WHONIX}" == "template" ]; then
    # Array of directories to bind
    BINDS=(
        '/rw/srv/whonix/root/.whonix:/root/.whonix'
        '/rw/srv/whonix/root/.whonix.d:/root/.whonix.d'
        '/rw/srv/whonix/var/lib/whonix:/var/lib/whonix'
        '/rw/srv/whonix/var/lib/whonixcheck:/var/lib/whonixcheck'
        '/rw/srv/whonix/etc/tor:/etc/tor'
    )

    for bind in ${BINDS[@]}; do
        rw_dir="${bind%%:*}"
        ro_dir="${bind##*:}"
    
        # Make sure ro directory is not mounted
        umount "${ro_dir}" 2> /dev/null || true
    
        if [ -n "${1}" ]; then
            echo "Umounting only..."
            exit 0
        fi
    
        # Make sure ro directory exists
        if ! [ -d "${ro_dir}" ]; then
            mkdir -p "${ro_dir}" 
        fi

        # Initially copy over data directories to /rw if rw directory does not exist
        if ! [ -d "${rw_dir}" ]; then
            mkdir -p "${rw_dir}"
            rsync -hax "${ro_dir}/." "${rw_dir}"
        fi
        
        # Bind the directory
        sync
        mount --bind "${rw_dir}" "${ro_dir}"
    done
    sync
fi

if [ "${WHONIX}" == "gateway" ]; then
    # Make sure we remove whonixsetup.done if Tor is not enabled
    # to allow choice of repo and prevent whonixcheck errors
    grep "^DisableNetwork 0$" /etc/tor/torrc || {
        sudo rm -f /var/lib/whonix/do_once/whonixsetup.done
    }
fi

exit 0
