#!/bin/bash
# CAP-Warn upgrade script
# (c) 2026 KJ5MZL — la2way.com
#
# This does upgrades and repairs bugs
#
#
#

echo "Setting up ca-warn due to upgrades  ....."

# Remove old WX sound directory if it exists
if [ -d "/var/lib/cap-warn/sounds/wx" ]; then
    rm -rf /var/lib/cap-warn/sounds/wx
    echo "Sound Upgrade.."
fi

# Remove incorrectly named new-sounds directory if it exists
if [ -d "/var/lib/cap-warn/new-sounds" ]; then
    rm -rf /var/lib/cap-warn/new-sounds
    echo "Removed misnamed directory: new-sounds"
fi

exit 0
