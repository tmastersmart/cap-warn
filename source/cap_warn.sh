#!/bin/bash
# Require sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run CAP-Warn using: sudo bash /usr/bin/cap-warn/sudo cap_warn"
    exit 1
fi
# Wrapper for CAP‑Warn
# Passes all arguments from cron or CLI directly to the PHP script.

# --- Repair CAP-Warn temp file permissions ---
TMP_PREFIXES=(
    "alert"
    "alerts_point"
    "alerts_zone"
    "points_zone_debug"
    "geocode"
    "forcast"
    "current"
    "warn_headline"
    "warn_description"
    "warn_special-weather"
    "cyclone"
    "alert-played"
    "alert-temp-played"
)

for prefix in "${TMP_PREFIXES[@]}"; do
    for f in /tmp/${prefix}*; do
        [ -e "$f" ] || continue

        # Fix ownership if not root
        if [ "$(stat -c %U "$f")" != "root" ]; then
            chown root:root "$f"
        fi

        # Fix permissions (read/write for all)
        chmod 666 "$f"
    done
done




PHP_BIN="/usr/bin/php"
APP="/usr/share/cap-warn/cap_warn.php"

# Forward ALL arguments ($@) to the PHP script
$PHP_BIN $APP "$@"
