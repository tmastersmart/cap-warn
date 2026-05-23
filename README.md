# CAP-Warn  
### NOAA / NWS Weather Alert Monitor for Linux Systems  
**Copyright (c) 2023–2026  KJ5MZL / WRXB288 — la2way.com - lagmrs.com All Rights Reserved.**

Software made in loUiSiAna its just better.

CAP-Warn is a closed‑source weather alert system designed for Linux hosts.  
It monitors National Weather Service (NWS) CAP alerts and provides automated  
audio warnings using VoiceRSS Text‑To‑Speech.

This repository contains the **APT repository files only**.  
The application itself is not open‑source.

---

## Installation (Webmin‑Style One‑Line Installer)
For debin. If you have something else do a manual install.

If you found this repository and want to install CAP‑Warn on a supported  
Linux system, you may use the automated installer:

curl -fsSL https://raw.githubusercontent.com/tmastersmart/cap-warn/main/install_capwarn.sh
You may view the installer online. If you wish to.

This installer will:

- Install the CAP‑Warn APT signing key  
- Add the CAP‑Warn APT repository  
- Update your package list  
- Install the `cap-warn` package  

You may wish to read the release blog post first. https://www.lagmrs.com/wp/

---

## Important: VoiceRSS API Key Required

Before running `setup.sh` after installation, you **must** have a free  
VoiceRSS Text‑To‑Speech API key.
You can obtain one at:
https://www.voicerss.org/
Setup will complete without this key but it will only use canned sounds.
---

## Automatic Updates
Once installed, CAP‑Warn will receive updates automatically through APT:

after install from now own you will get upgrades via the update system 

sudo apt update
sudo apt upgrade

