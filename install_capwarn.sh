#!/bin/bash
set -e

# ============================================================
#  CAP-Warn Installer Script
#  Copyright (c) 2023-2026
#  KJ5MZL / WRXB288 — la2way.com
#  All Rights Reserved. Not open-source software.
#
#  This installer configures the CAP-Warn APT repository,
#  installs the trusted signing key, and installs the package.
#
#  IMPORTANT:
#  Before running setup.sh after installation, you MUST have
#  a free VoiceRSS Text-To-Speech API key ready.
#  Get one at: https://www.voicerss.org/
# ============================================================

echo "============================================================"
echo " CAP-Warn Installer (c)2026 by KJ5MZL Made in Louisiana"
echo "============================================================"
echo ""
echo "Before running setup.sh you MUST have a VoiceRSS API key."
echo "Get one free at: https://www.voicerss.org/"
echo "You can get one first or get it after install and before running setup"
read -p "Press ENTER to continue... "

# ============================================================
# Install GPG key
# ============================================================
echo "Installing CAP-Warn repository key..."

curl -fsSL https://raw.githubusercontent.com/tmastersmart/cap-warn/main/debian/public.key \
  | sudo gpg --dearmor -o /usr/share/keyrings/capwarn.gpg

echo "Key installed."

# ============================================================
# Add APT source
# ============================================================
echo "Adding CAP-Warn APT repository..."

sudo bash -c 'cat > /etc/apt/sources.list.d/capwarn.list <<EOF
deb [signed-by=/usr/share/keyrings/capwarn.gpg] https://raw.githubusercontent.com/tmastersmart/cap-warn/main/debian stable main
EOF'

echo "Repository added."

# ============================================================
# Update APT
# ============================================================
echo "Updating package lists..."
sudo apt update

# ============================================================
# Install CAP-Warn
# ============================================================
echo "Installing CAP-Warn..."
sudo apt install -y cap-warn

echo ""
echo "============================================================"
echo " CAP-Warn installation complete! Made in Louisiana"
echo " Next step:"
echo "   cd /usr/share/cap-warn"
echo "   sudo bash setup.sh"
echo ""
echo "Remember: setup.sh will require your VoiceRSS API key."
echo "============================================================"
