source /usr/lib/qubes-whonix/utility_functions

if [ "${QUBES_WHONIX}" == "unknown" ]; then
    export UWT_DEV_PASSTHROUGH=1
fi
