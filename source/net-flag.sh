# -----------------------------------------------------------------------------
# NET-LINK SUPPRESSION CONTROL (net-flag)
# -----------------------------------------------------------------------------
# This system uses a simple flag file to control whether the hub is allowed to
# transmit while linked or during scheduled nets.
#
# FLAG FILE:
#     /tmp/linked_true.txt
#
# When this file exists:
#     • The hub suppresses all outbound transmissions
#     • Used during nets or when bridged to another hub
#
# When the file is removed:
#     • Normal operation resumes
#
# SCRIPT LOCATION:
#     /usr/bin/cap-warn/net-flag.sh
#
# This script was moved to the same directory as the wrapper so it is always
# available in PATH and consistent with other runtime utilities.
#
# USAGE:
#     net-flag on        → enable suppression (create flag)
#     net-flag off       → disable suppression (remove flag)
#     net-flag toggle    → flip current state
#     net-flag status    → show current state
#
# CRON AUTOMATION EXAMPLE:
#     # Enable suppression at net start (18:30)
#     30 18 * * * /usr/bin/cap-warn/net-flag.sh on
#
#     # Disable suppression at net end (19:30)
#     30 19 * * * /usr/bin/cap-warn/net-flag.sh off
#
# NOTES:
#     • The flag lives in /tmp, so it clears automatically on reboot.
#     • This prevents accidental transmissions during nets or while linked.
# -----------------------------------------------------------------------------

# 
#!/bin/bash

FLAG="/tmp/linked_true.txt"

case "$1" in
    on)
        touch "$FLAG"
        echo "Net flag ENABLED (hub will not talk while linked)."
        ;;
    off)
        rm -f "$FLAG"
        echo "Net flag DISABLED (normal operation restored)."
        ;;
    toggle)
        if [ -f "$FLAG" ]; then
            rm -f "$FLAG"
            echo "Net flag toggled OFF."
        else
            touch "$FLAG"
            echo "Net flag toggled ON."
        fi
        ;;
    status)
        if [ -f "$FLAG" ]; then
            echo "Net flag is ON (hub is muted)."
        else
            echo "Net flag is OFF (hub is active)."
        fi
        ;;
    *)
        echo "Usage: $0 {on|off|toggle|status}"
        exit 1
        ;;
esac
