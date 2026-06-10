#!/bin/bash
set -e
#   (c)2023/2026 Cap-warn is made in Louisiana KJ5MZL
#
#
#  
echo "============================================================"
echo " CAP-Warn Easy Installer — Made in Louisiana"
echo "============================================================"
echo "Initializing… please wait while the vacuum tubes warm up."
echo ""
echo ""
echo ""
echo "Before running setup.sh you should get a VoiceRSS API key."
echo "Get one free at: https://www.voicerss.org/"
echo "If you dont have one the asl3 Piper will be installed."
echo "If you have a PI please use Voicerss.prg API Key"
echo ""
read -p "Press ENTER to continue... "
echo "Thank you. Your response has been recorded on magnetic tape."

echo ""
echo "Installing CAP-Warn repository key..."
echo "Please stand by. Operator is loading punch cards."

if ! curl -sSL https://raw.githubusercontent.com/tmastersmart/cap-warn/main/debian/public.key \
    | sudo gpg --dearmor -o /usr/share/keyrings/capwarn.gpg; then
    echo "ERROR: Failed to download or install GPG key."
    echo "Suggestion: Try reseating the vacuum tubes."
    exit 1
fi

echo "Key installed. No punch cards were harmed."

echo ""
echo "Adding CAP-Warn APT repository..."
echo "Do not fold, spindle, or mutilate this repository."

if ! sudo bash -c 'cat > /etc/apt/sources.list.d/capwarn.list <<EOF
deb [arch=all signed-by=/usr/share/keyrings/capwarn.gpg] https://raw.githubusercontent.com/tmastersmart/cap-warn/main/debian stable main
EOF'; then
    echo "ERROR: Failed to write APT source file."
    echo "Please notify the nearest mainframe operator."
    exit 1
fi

echo "Repository added. Magnetic tape rewinding..."

echo ""
echo "Updating package lists..."
if ! sudo apt update; then
    echo "ERROR: APT update failed."
    echo "Possible cause: cosmic rays or gremlins in the punch cards."
    exit 1
fi

echo ""
echo "Installing CAP-Warn..."
echo "Please wait. The system is calculating using state-of-the-art 1960s math."

if ! sudo apt install -y cap-warn; then
    echo "ERROR: Failed to install CAP-Warn."
    echo "Try again after adjusting the vacuum tube bias."
    exit 1
fi



echo "============================================================"
echo " CAP-Warn installation complete!"
echo " This system now has more power than NASA had in 1969."
echo " "
echo " Welcome to software made in Louisiana — it's just better."
echo " Get your node setup fast no editing."
echo "============================================================"

cd /usr/share/cap-warn
echo ""
echo "Get your node# Lat/Lon and KEY ready"
echo ""
echo "You are now in the CAP-Warn directory."
echo "To complete setup run setup system, type:"
echo "  sudo bash setup.sh"


