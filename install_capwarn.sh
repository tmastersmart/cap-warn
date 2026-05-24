#!/bin/bash
set -e

# ============================================================
#  CAP-Warn Installer Script
# ============================================================

echo "============================================================"
echo " CAP-Warn Installer (c)2026 by KJ5MZL Made in Louisiana"
echo "============================================================"
echo ""
echo "You will need a VoiceRSS API key. To do custom text to speach"
echo "Get one free at: https://www.voicerss.org/"
echo ""
read -p "Press ENTER to continue... "

# ============================================================
# Install GPG key
# ============================================================
echo "Ive got a KEY for you. Its a fancy key "
echo "Installing CAP-Warn repository key..."

if ! curl -sSL https://raw.githubusercontent.com/tmastersmart/cap-warn/main/debian/public.key \
    | sudo gpg --dearmor -o /usr/share/keyrings/capwarn.gpg; then
    echo "ERROR: Failed to download or install GPG key."
    exit 1
fi

echo "Key installed."

# ============================================================
# Add APT source
# ============================================================
echo "Adding CAP-Warn APT repository..."

if ! sudo bash -c 'cat > /etc/apt/sources.list.d/capwarn.list <<EOF
deb [signed-by=/usr/share/keyrings/capwarn.gpg] https://raw.githubusercontent.com/tmastersmart/cap-warn/main/debian stable main
EOF'; then
    echo "ERROR: Failed to write APT source file."
    exit 1
fi

echo "Repository added."

# ============================================================
# Update APT
# ============================================================
echo "Updating package lists..."
if ! sudo apt update; then
    echo "ERROR: APT update failed. Check your repository configuration."
    exit 1
fi

# ============================================================
# Install CAP-Warn
# ============================================================
echo "Installing CAP-Warn..."
if ! sudo apt install -y cap-warn; then
    echo "ERROR: Failed to install CAP-Warn package."
    exit 1
fi

echo ""
echo "============================================================"
echo " CAP-Warn installation complete! Made in Louisiana"
echo "============================================================"
echo ""

# ============================================================
# Ask user if they want to run setup.sh
# ============================================================
read -p "Would you like to run setup.sh now? (y/N): " RUNSETUP

case "$RUNSETUP" in
    y|Y|yes|YES)
        echo ""
        echo "Launching setup.sh..."
        cd /usr/share/cap-warn
        sudo bash setup.sh
        ;;
    *)
        echo ""
        echo "You can run setup later with:"
        echo "  cd /usr/share/cap-warn"
        echo "  sudo bash setup.sh"
        ;;
esac

echo ""
echo "============================================================"
echo " CAP-Warn is installed and ready."
echo "Welcome to software made in loUiSiAna its just better"
echo "============================================================"
