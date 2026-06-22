# CAP‑Warn  
### NOAA / NWS Weather Alerts for ASL3 and AllStar — Modern Skywarn Replacement  
<img width="1024" height="1024" alt="Copilot_20260524_010328" src="https://github.com/user-attachments/assets/b00a748c-2858-40aa-be8b-c80b26fff8fc" />
**© 2023–2026 KJ5MZL / WRXB288 — la2way.com • lagmrs.com — All Rights Reserved.**

[Read the CAP‑Warn Release Blog Post](https://www.lagmrs.com/wp/2026/05/24/cap-warn-a-modern-actively-maintained-replacement-for-skywarn-scripts/)

Updated info will be on the blog post.

Software made in loUiSiAna — it’s just better.  
No more manually installing on ASL3. All my programs now include an installer and an update repository.

---

## About CAP‑Warn

CAP‑Warn is a 100% new not based on any other code, actively maintained weather alert system for Linux hosts.  
It monitors **National Weather Service (NWS) CAP alerts**, generates **automated audio warnings**, and includes **high‑temperature monitoring for Raspberry Pi systems**.

This repository contains the **APT repository files** used for installation and updates.  
If you want to install CAP‑Warn on a supported Linux system, use the one‑line installer below.<img width="80" height="44" alt="Apt-get_logo" src="https://github.com/user-attachments/assets/c7e6b457-99fa-4f52-accd-43ee713299ce" />

---

## Installation (One‑Line Installer)

For Debian‑based systems:

curl -fsSL https://raw.githubusercontent.com/tmastersmart/cap-warn/main/install_capwarn.sh | sudo bash


You may also view the installer online if you wish.

The installer will:

- Install the CAP‑Warn APT signing key  
- Add the CAP‑Warn APT repository  
- Update your package list  
- Install the `cap-warn` package  

You may want to read the blog first:  
[Visit the CAP‑Warn Blog](https://www.lagmrs.com/wp/)

---

## VoiceRSS API Key (Optional)

CAP‑Warn supports **VoiceRSS Text‑To‑Speech** for higher‑quality audio output.  
You can obtain a free API key here:

[VoiceRSS Website](https://www.voicerss.org/)

If you do not provide a key, CAP‑Warn will fall back to the built‑in ASL3 TTS system.

---

## Automatic Updates

Once installed, CAP‑Warn updates automatically through APT.

To manually update:

sudo apt update
sudo apt upgrade cap-warn



No more manual installs — CAP‑Warn now updates with your normal system packages.

---

## Features

- **Automatic GPS‑Based Alert Targeting**  
  CAP‑Warn uses your latitude and longitude to automatically determine your forecast zone, county/parish zone, and fire weather zone. No UGC codes or manual configuration required.

- **NWS CAP Alert Monitoring**  
  Continuously monitors the National Weather Service CAP feed for watches, warnings, advisories, and special weather statements relevant to your exact location.

- **Hurricane & Tropical Cyclone Tracking**  
  Automatically fetches National Hurricane Center (NHC) cyclone advisories and announces only new advisories, with distance filtering to avoid irrelevant storms.

- **High‑Quality Text‑to‑Speech**  
  Supports VoiceRSS for natural‑sounding speech, with fallback to ASL3’s built‑in TTS if no API key is provided.

- **Automatic APT Updates**  
  CAP‑Warn installs as a Debian package and updates through your normal `apt upgrade` process — no more manual installs or script replacements.<img width="80" height="44" alt="Apt-get_logo" src="https://github.com/user-attachments/assets/c7e6b457-99fa-4f52-accd-43ee713299ce" />

- **Smart Cron Scheduling**  
  Runs on a safe, offset schedule that avoids the top‑of‑hour NWS/NHC update storm and system clock sync events.

- **Zone + Point Alert Merging**  
  Combines point‑based alerts with zone‑level alerts to ensure complete coverage, including polygon warnings and county‑wide advisories.

- **Pi Temperature Monitoring**  
  Monitors Raspberry Pi CPU temperature and issues alerts if overheating is detected.

- **Installer + Setup Wizard**  
  One‑line installer, automatic repo setup, and a guided setup script that configures everything without requiring technical knowledge.

- **Actively Maintained**  
  100% original code written in PHP — not based on Skywarn, SkywarnPlus, or any legacy scripts. Fully maintained and updated.<img width="80" height="15" alt="php-power-micro2" src="https://github.com/user-attachments/assets/94f0f6a7-64e9-40bc-aa22-b01cdcc22919" />

- **Pushover Support**
  Will send you pushover events Temp Alarms and weather alerts
---

## Goals

1. **Create a modern replacement for Skywarn/SkywarnPlus**  
   No Perl, no reused code — CAP‑Warn is 100% new and written entirely in PHP.

2. **Make installation and updates effortless**  
   Everything installs via APT and updates automatically.  
   No zone codes, no UGC lists — just enter your **latitude and longitude**.

3. **Provide hurricane monitoring for coastal users**  
   CAP‑Warn tracks active cyclones and reports new advisories as they are released by the National Hurricane Center.
   
4. **Provide a light weight utility that wont overload the cpu.**
   Overloading the CPU is a major problem on HUBs and pis so we need to keep the package light and exit when done.

5. **Intergration into the status page**
   (planning stage) allowing cap-warn-weather to display the weather in any front end webserver by including
   a php file. This is compleated but packaging and setup files need to be changed for install. 

## Why I Use Cron Instead of a System Service
CAP‑Warn is designed to run as a lightweight polling script, not a full‑time daemon. It wakes up, checks for new alerts, processes them, and exits. Because of this design, using cron is the most efficient and reliable choice. Cron allows users to choose how often CAP‑Warn runs, supports safe offset scheduling to avoid the top‑of‑hour NWS/NHC update surge, and keeps the system simple without requiring a persistent background service. A systemd service is ideal for programs that must run continuously or restart automatically, but CAP‑Warn doesn’t need that overhead. Cron provides predictable timing, low resource usage, and easy user configuration — making it the right tool for this job. And keeping with goal 4 above.


## History
This project is based on earlier work originally developed for the
GMRS Live program and the first CAP-Warn system released in 2023. The
original codebase is archived here:

https://github.com/tmastersmart/gmrs_live
https://github.com/tmastersmart/allstar/
Code was distributed in a zip file and installed by my custom
scripts. (c)2023/2026

They were all based on a weather program I wrote is 2018
https://pws.winnfreenet.com
To post weather to Citizens Weather Observation Program 
(c)2018/2026

CAP-Warn-Weather is a complete redesign and modernization of that
earlier system, but it continues the same core concepts, alert handling
logic, and overall philosophy established in the GMRS Live era.

New in the new version is that its installed by APT-GET not my installer.
It may not work they way others do but thats because I wrote it.




(c)2023/2026 All rights reserved. I wrote it. <img width="200" height="25" alt="copyscape-banner-white-200x25" src="https://github.com/user-attachments/assets/c1662005-fd61-4b98-92c8-19c72f6420eb" />


