#!/bin/bash
# ------------------------------------------------------------
# CAP-Warn Setup Utility
# ------------------------------------------------------------
# This setup program configures CAP-Warn for your node.
# In the spirit of 1960s computer rooms:
#   "Please do not fold, spindle, or mutilate this installer."
#
# And as Buckaroo Banzai wisely said:
#   "Wherever you go... there you are."
# ------------------------------------------------------------
cd /usr/share/cap-warn
#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8
#export TERM=xterm-256color
# ------------------------------------------------------------
# Commodore 64 Style Boot Screen
# ------------------------------------------------------------
echo " "
echo " **** COMMODORE 64 BASIC V2 ****"
echo " "
echo " 64K RAM SYSTEM  38911 BASIC BYTES FREE"
echo " "
echo "READY."
sleep 1
echo "LOAD \"CAP-WARN SETUP\",8,1"
sleep 1
echo "SEARCHING FOR CAP-WARN SETUP"
echo "LOADING"
echo " "
echo "Hang loose… CAP‑Warn is loading its cosmic subroutines."
echo "Outta sight… CAP‑Warn is warming up.."
echo " "

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------
LOGDIR="/var/log/cap-warn"
LOGFILE="$LOGDIR/install.log"
mkdir -p "$LOGDIR"
touch "$LOGFILE"
chmod 644 "$LOGFILE"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S')  $1" >> "$LOGFILE"
}

log "===== CAP-WARN INSTALLER STARTED ====="

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------
CONFIG="/etc/cap-warn/config.php"
mkdir -p /etc/cap-warn
chmod 755 /etc/cap-warn
log "Ensured /etc/cap-warn exists."

# ------------------------------------------------------------
# Auto-increment installer version (persists forever)
# ------------------------------------------------------------
SETUPVERFILE="/usr/share/cap-warn/setup_version.txt"

if [ ! -f "$SETUPVERFILE" ]; then
    echo "1" > "$SETUPVERFILE"
fi

SETUPVER=$(cat "$SETUPVERFILE")
NEWSETUPVER=$((SETUPVER + 1))
echo "$NEWSETUPVER" > "$SETUPVERFILE"
INSTALLER_VERSION="$NEWSETUPVER"
log "Edited $INSTALLER_VERSION Times"

# ------------------------------------------------------------
# Load existing config values (if present)
# ------------------------------------------------------------
OLD_NODE=""
OLD_TTS=""
OLD_LAT=""
OLD_LON=""
OLD_STORMRADIUS=""
OLD_DETECTCYCLONE=""
OLD_CYURL=""
OLD_EXPANALERT=""
OLD_SLEEP=""
OLD_HOLDTIME=""
OLD_CRONINT=""
OLD_PIALARMS=""
OLD_SOFT=""
OLD_HOT=""
OLD_HURONLY=""  

if [ -f "$CONFIG" ]; then
    log "Loading existing configuration from $CONFIG"
    OLD_NODE=$(php -r "include '$CONFIG'; echo \$node ?? '';")
    OLD_TTS=$(php -r "include '$CONFIG'; echo \$tts ?? '';")
    OLD_LAT=$(php -r "include '$CONFIG'; echo \$lat ?? '';")
    OLD_LON=$(php -r "include '$CONFIG'; echo \$lon ?? '';")
    OLD_STORMRADIUS=$(php -r "include '$CONFIG'; echo \$stormRadiusMiles ?? '';")
    OLD_DETECTCYCLONE=$(php -r "include '$CONFIG'; echo \$detectCyclone ?? '';")
    OLD_CYURL=$(php -r "include '$CONFIG'; echo \$cycloneURL ?? '';")
    OLD_EXPANALERT=$(php -r "include '$CONFIG'; echo \$expanAlert ?? '';")
    OLD_SLEEP=$(php -r "include '$CONFIG'; echo \$sleep ?? '';")
    OLD_HOLDTIME=$(php -r "include '$CONFIG'; echo \$theHoldtime ?? '';")
    OLD_CRONINT=$(php -r "include '$CONFIG'; echo \$cronInt ?? '';")
    OLD_PIALARMS=$(php -r "include '$CONFIG'; echo \$piAlarms ?? '';")
    OLD_SOFT=$(php -r "include '$CONFIG'; echo \$soft ?? '';")
    OLD_HOT=$(php -r "include '$CONFIG'; echo \$hot ?? '';")
    OLD_HURONLY=$(php -r "include '$CONFIG'; echo \$hurOnly ?? '';")
fi

# Smart defaults when missing
[ -z "$OLD_STORMRADIUS" ] && OLD_STORMRADIUS="1000"
[ -z "$OLD_HOLDTIME" ] && OLD_HOLDTIME="25"
[ -z "$OLD_CRONINT" ] && OLD_CRONINT="13"
[ -z "$OLD_SOFT" ] && OLD_SOFT="65"
[ -z "$OLD_HOT" ] && OLD_HOT="75"
[ -z "$OLD_HURONLY" ] && OLD_HURONLY="false"

# ------------------------------------------------------------
# Detect Raspberry Pi hardware
# ------------------------------------------------------------
piSystem=false
if [[ -r /proc/device-tree/model ]]; then
    piSystem=true
    piVersion=$(tr -d '\0' < /proc/device-tree/model)
else
    piVersion="$(uname -m -s -o -v)"
fi
log "Detected system: $piVersion"

# Keep original stdout on FD 3 for whiptail
exec 3>&1


# ------------------------------------------------------------
# Choose installer mode
# ------------------------------------------------------------
if whiptail --title "CAP-Warn Installer Mode" --yesno "\
Installer can run in two modes:

  Graphic Mode (whiptail)
     Recommended for Raspberry Pi, SSH, and most terminals.
     Uses dialog-style menus and input boxes. With help.

  Text Mode (setup_text.sh)
     Recommended if:
       - You cannot type in whiptail boxes
       - Your terminal does not support dialog
       - You prefer plain text prompts
       - You dont need help

Would you like to continue in Graphic Mode?

Choose NO to switch to Text Mode." 20 70
then
    # User chose YES → continue normally
    :
else
    echo ""
    clear
    echo "Switching to text-only installer..."
    echo ""
    sleep 1
    bash /usr/share/cap-warn/setup_text.sh
    exit 0
fi






# ------------------------------------------------------------
# Splash
# ------------------------------------------------------------
if ! whiptail --title "CAP Warn Installer — Setup:$INSTALLER_VERSION" --yesno "\
CAP-Warn Setup Program
(c) 2023/2026 KJ5MZL  la2way.com
All rights reserved.
$piVersion

CAP-Warn is an automated alerting system that retrieves
National Weather Service CAP (Common Alerting Protocol)
messages, processes them, and plays alerts over your
AllStar node or repeater.

This installer will configure:
 1 Node number
 2 Lat/Lon defaults or GPS auto-detection
 3 Hurricane tracking region
 4 Alert behavior and timing
 5 Text-to-speech options

Press YES to begin installation.
Press NO to abort." 22 78
then
    echo "Installation aborted by user."
    exit 1
fi

log "Displayed splash screen."

# Keep only the 5 most recent config backups
BACKUP_DIR="/etc/cap-warn"
BACKUP_PATTERN="config.php.bak_*"

# List backups sorted by newest first, skip first 5, delete the rest
ls -1t $BACKUP_DIR/$BACKUP_PATTERN 2>/dev/null | tail -n +6 | while read old; do
    rm -f "$old"
    log "Removed old backup: $old"
done
# ------------------------------------------------------------
# TTS Engine Information
# ------------------------------------------------------------
whiptail --title "Text to Speech Options" \
--msgbox "CAP-Warn supports two text to speech engines:\n
1. VoiceRSS (Recommended)
   Most natural human sounding voice
   Requires internet and a FREE API key
   Used when cloud TTS is available\n
2. Piper / asl-tts (Offline Mode)
   No API key required
   Works without internet
   Slightly more robotic slower\n
   In testing on a PI3b it used 100% CPU not recomended for a PI

If you enter a VoiceRSS key, CAP-Warn will use the high quality cloud voice.
If you skip the key, CAP-Warn will use asl-tts (dont use on PI)" \
25 70
log "Displayed TTS engine information."

# ------------------------------------------------------------
# TTS API Key (Optional)
# ------------------------------------------------------------
TTSKEY=$(whiptail --inputbox "Enter your VoiceRSS API key (leave blank for asl-tts):" \
10 70 "$OLD_TTS" --title "VoiceRSS API Key (Optional)" 2>&1 1>&3)
log "TTS API key entered (blank means offline mode). $TTSKEY"


# Detect if Piper (asl-tts) is already installed
if command -v asl-tts >/dev/null 2>&1; then
    HAS_PIPER=1
else
    HAS_PIPER=0
fi

if [ "$piSystem" = true ] && [ -z "$TTSKEY" ]; then
    whiptail --title "WARNING: Local TTS Performance" \
    --yesno "No VoiceRSS API key detected.\n\nUsing locally generated TTS audio on a Raspberry Pi may cause:\n\n • 100% CPU usage\n • Audio dropouts\n • Jitter on RF output\n\nIt is strongly recommended to use VoiceRSS instead.\n\nDo you want to continue anyway?" 18 70

    if [ $? -ne 0 ]; then
        echo "User cancelled due to TTS warning. Exiting installer."
        log "User cancelled due to TTS warning"
        exit 1
    fi
fi







# If no API key AND Piper not installed → install it
if [ -z "$TTSKEY" ] && [ "$HAS_PIPER" -eq 0 ]; then

    {
        echo 10
        echo "20 Preparing to install offline Piper/asl-tts .." ; sleep 0.2
        echo 40
        echo "60 Installing asl3-tts/asl-tts ..." ; sleep 0.2

        # Install Piper TTS (no apt update needed)
        apt-get install -y asl3-tts >/dev/null 2>&1

        echo 90
        echo "100 Installation complete." ; sleep 0.2
    } | whiptail --gauge "Installing offline Piper/asl-tts ..." 8 60 0

    log "Installed asl3-tts for offline TTS."

elif [ -z "$TTSKEY" ] && [ "$HAS_PIPER" -eq 1 ]; then
    log "Offline Piper TTS already installed — skipping installation."

else
    log "Using VoiceRSS — offline Piper TTS not required."
fi








# ================================================================
# Latitude + Longitude (Combined to prevent skipping bug)
# ================================================================
COORDS=$(whiptail --inputbox "\
Enter your default Lat /Lon Coordinates:

Latitude Longitude (example: 31.00 -92.00) 
If you have a GPS it will overide once locked.

You can press Enter to keep current values." 14 70 "$OLD_LAT $OLD_LON" --title "Lat Lon Coordinates" 2>&1 1>&3)

if [[ $? -ne 0 ]]; then
    echo "Cancelled by user."
    exit 1
fi

# Parse the two values
LAT=$(echo "$COORDS" | awk '{print $1}')
LON=$(echo "$COORDS" | awk '{print $2}')

# Use defaults if empty
[[ -z "$LAT" ]] && LAT="$OLD_LAT"
[[ -z "$LON" ]] && LON="$OLD_LON"

log "Latitude: $LAT"
log "Longitude: $LON"

# ================================================================
# Node Number
# ================================================================
NODE=$(whiptail --inputbox "Enter your AllStar node number:" 10 60 "$OLD_NODE" --title "Node Number" 2>&1 1>&3)
if [[ $? -ne 0 ]]; then
    echo "Cancelled by user."
    exit 1
fi
[[ -z "$NODE" ]] && NODE="$OLD_NODE"
log "Node number: $NODE"

sleep 0.3   # Small delay to stabilize terminal




# ------------------------------------------------------------
# Hurricane Basin
# ------------------------------------------------------------
DEFAULT_CHOICE="0"
case "$OLD_CYURL" in
    "/gis-at.xml") DEFAULT_CHOICE="1" ;;
    "/gis-ep.xml") DEFAULT_CHOICE="2" ;;
    "/gis-cp.xml") DEFAULT_CHOICE="3" ;;
    *) DEFAULT_CHOICE="0" ;;
esac

CHOICE=$(whiptail --default-item "$DEFAULT_CHOICE" --title "Select Hurricane Feed (NHC GIS)" --menu "\
CAP-Warn can monitor tropical systems directly from the
National Hurricane Center (NHC). This includes tropical
depressions, tropical storms, hurricanes, and other
cyclone advisories. These alerts are in addition to
your normal NWS warnings.

Hurricane messages will be played once when released
and will not repeat. Alerts are spoken at the timing
set by the NHC, which may not align with your local
quiet hours or system activity.

Recommended for nearby nodes. On busy or wide-area
systems, this may produce more traffic than desired.
Reduce the distance filter to limit reports.

Choose the region closest to your location:" 28 79 10 \
"1" "Atlantic/Gulf (LA TX MS AL FL GA SC NC VA MD NJ NY MA ME)" \
"2" "Eastern Pacific (Ca, Az, Baja California, Mexico West Coast)" \
"3" "Central Pacific (Hawaii region)" \
"0" "Disable hurricane detection" \
2>&1 1>&3)


case $CHOICE in
    1) CYURL="/gis-at.xml"; DETECTCYCLONE=true ;;
    2) CYURL="/gis-ep.xml"; DETECTCYCLONE=true ;;
    3) CYURL="/gis-cp.xml"; DETECTCYCLONE=true ;;
    0) CYURL="disabled"; DETECTCYCLONE=false ;;
esac

log "Cyclone detection: $DETECTCYCLONE, URL: $CYURL"

# ------------------------------------------------------------
# Storm Radius
# ------------------------------------------------------------
if [ "$DETECTCYCLONE" = true ]; then
STORMRADIUS=$(whiptail --inputbox "\
Enter the maximum distance (in miles) to announce tropical systems.

This setting applies ONLY to tropical cyclones from the
National Hurricane Center (NHC) such as Tropical Storms
and Hurricanes. It does NOT affect NWS tornado or severe
weather alerts.

Set to 0 to disable distance filtering." \
12 70 "$OLD_STORMRADIUS" \
--title "Cyclone Distance Filter" \
2>&1 1>&3)
else
    STORMRADIUS=0
fi
log "Storm radius: $STORMRADIUS"


# Load previous setting
REPORT_HURRICANE_ONLY="$OLD_HURONLY"

whiptail --title "Tropical Storm Reporting" \
--yesno "Do you want to announce ALL tropical systems (Tropical Storms, Depressions, etc.)?\n\nChoose NO to announce ONLY Hurricanes." \
10 60

if [ $? -eq 0 ]; then
    # User chose YES → report all tropical systems
    REPORT_HURRICANE_ONLY="false"
else
    # User chose NO → hurricane-only mode
    REPORT_HURRICANE_ONLY="true"
fi

log "Hurricane only: $REPORT_HURRICANE_ONLY"




# ------------------------------------------------------------
# Expanded Alert Descriptions
# ------------------------------------------------------------
if [[ "$OLD_EXPANALERT" == "true" ]]; then
    DEFAULT="--defaultyes"
else
    DEFAULT="--defaultno"
fi

whiptail $DEFAULT --yesno "\
Enable expanded alert descriptions?

CAP-Warn normally plays a alert headline phrase for most
NWS alert types (Tornado Warning, Severe Thunderstorm,
Flash Flood, etc.). If you enable this option, CAP-Warn
will also read the full text description using text-to-
speech (TTS) for those alerts.

Special Weather Statements (SWS) are ALWAYS expanded
because their content varies widely and cannot use a
standard sound.

Enable expanded descriptions for all other alerts?" \
14 70 --title "Expanded Alert Details"

EXPANALERT=$([ $? -eq 0 ] && echo true || echo false)
log "Expand alerts: $EXPANALERT"

# ------------------------------------------------------------
# Quiet Hours
# ------------------------------------------------------------
if [[ "$OLD_SLEEP" == "true" ]]; then
    DEFAULT="--defaultyes"
else
    DEFAULT="--defaultno"
fi

whiptail $DEFAULT --yesno "\
Enable Quiet Hours (1AM - 6AM)?

When Quiet Hours are enabled, CAP-Warn will NOT speak
any alerts during overnight hours. This includes NWS
warnings and tropical cyclone announcements.

Alerts will still be logged, but no audio will be played.
This option is useful if your node is in a bedroom or
you prefer silence overnight.

Enable Quiet Hours?" \
14 70 --title "Quiet Hours (Mute Overnight)"

SLEEP=$([ $? -eq 0 ] && echo true || echo false)
log "Quiet hours: $SLEEP"


# ------------------------------------------------------------
# Hold Timer
# ------------------------------------------------------------
HOLDTIME=$(whiptail --inputbox "\
Minutes to wait before repeating the SAME NWS alert.

This applies ONLY to National Weather Service alerts
(Tornado Warnings, Severe Thunderstorm Warnings, etc.).

If the same alert is still active, CAP-Warn will wait
this long before speaking it again. This prevents
repeating the same alert too often.

Recommended: 25 minutes." \
14 70 "$OLD_HOLDTIME" \
--title "Hold Timer (NWS Alerts Only)" \
2>&1 1>&3)

log "Hold time: $HOLDTIME"


# ------------------------------------------------------------
# Cron Interval
# ------------------------------------------------------------
CRONINT=$(whiptail --inputbox "\
How often should CAP-Warn check for new alerts?

This controls how frequently the system runs its update
cycle (via cron). During each run, CAP-Warn checks for:

  New NWS alerts
  Expired alerts
  Updated alerts
  New tropical cyclone advisories (if enabled)

Shorter intervals mean faster updates, but more system
activity. Longer intervals reduce load but may delay
alert playback slightly.

Recommended: 5–10 minutes." \
16 70 "$OLD_CRONINT" \
--title "Alert Update Interval" \
2>&1 1>&3)

log "Cron interval: $CRONINT"



# Defaults
piAlarms="${OLD_PIALARMS:-false}"
piSoftTemp="$OLD_SOFT"
piHotTemp="$OLD_HOT"

# ------------------------------------------------------------
# Raspberry Pi alarm options
# ------------------------------------------------------------
if [[ "$piSystem" == true ]]; then
    if [[ "$piAlarms" == "true" ]]; then
        ALARM_CHOICE=0
        whiptail --yesno "Detected: $piVersion

Raspberry Pi alarms are currently ENABLED.

NOTE:
This feature is recommended for local Pi-based nodes.
It may cause excessive alarm traffic on distant repeaters.
A limiter will be added in a future version.

Would you like to keep them enabled?" \
        18 70
        [ $? -ne 0 ] && piAlarms="false"
    else
        whiptail --yesno "Detected: $piVersion

Would you like to enable the following alarms?

 High CPU Temperature
 Throttling Detection
 Low Voltage Alerts
 
NOTE:
This feature is recommended for local Pi-based nodes.
It may cause excessive alarm traffic on distant repeaters.
A limiter will be added in a future version.

Recommended for Raspberry Pi nodes." \
        18 70
        [ $? -eq 0 ] && piAlarms="true"
    fi

    if [[ "$piAlarms" == "true" ]]; then
        whiptail --title "Raspberry Pi Temperature Guidance" --msgbox "\
Detected: $piVersion

Raspberry Pi boards have built-in thermal protection:
 Soft throttling begins around 80 C
 Hard throttling begins around 85 C
 Emergency shutdown occurs near 90 C

Recommended alarm levels:
 Soft Warning: 65 C
 Critical Alarm: 75 C

You may manually adjust later in config files.

You will now be asked to enter your preferred thresholds." \
        22 75

        piSoftTemp=$(whiptail --inputbox "Detected: $piVersion

Enter SOFT warning temperature C:" \
            12 60 "$piSoftTemp" --title "Soft Temp Warning" 2>&1 1>&3)

        piHotTemp=$(whiptail --inputbox "Detected: $piVersion

Enter CRITICAL temperature C:" \
            12 60 "$piHotTemp" --title "Critical Temp Alarm" 2>&1 1>&3)
    fi
fi

log "Pi alarms: $piAlarms, soft: $piSoftTemp, hot: $piHotTemp"


# ================================================================
# FINAL CONFIRMATION SCREEN
# ================================================================
if whiptail --title "CAP-Warn Configuration Summary" --yesno "\
Ready to save the following configuration:

Node Number:          $NODE
Latitude:             $LAT
Longitude:            $LON
VoiceRSS Key:         ${TTSKEY:-(None - using offline TTS)}
Hurricane Detection:  $DETECTCYCLONE ($CYURL)
Storm Radius:         $STORMRADIUS miles
Hurricane Only:       $REPORT_HURRICANE_ONLY
Expanded Alerts:      $EXPANALERT
Quiet Hours:          $SLEEP
Hold Time:            $HOLDTIME minutes
Cron Interval:        $CRONINT minutes

Raspberry Pi Alarms:  $piAlarms
  Soft Warning:       $piSoftTemp°C
  Critical:           $piHotTemp°C

Press YES to save and continue.
Press NO to abort." 25 78
then
    echo "User confirmed - proceeding with save."
else
    echo "Installation aborted by user."
    exit 1
fi



# ------------------------------------------------------------
# Write config.php
# ------------------------------------------------------------
log "Writing config.php..."

cat > "$CONFIG" <<EOF
<?php
// ------------------------------------------------------------
// CAP-Warn Configuration File
// ------------------------------------------------------------
// This file is generated automatically by setup.sh.
// Running setup.sh again will update these values using
// your previous configuration as defaults.
//
// System detected: $piVersion
// Installer version: $INSTALLER_VERSION
// ------------------------------------------------------------
\$installerVer      = "$INSTALLER_VERSION";
\$node              = "$NODE";
\$tts               = "$TTSKEY";
\$lat               = "$LAT";
\$lon               = "$LON";
\$stormRadiusMiles  = $STORMRADIUS;
\$detectCyclone     = $DETECTCYCLONE;
\$cycloneURL        = "$CYURL";
\$hurOnly           = $REPORT_HURRICANE_ONLY;
\$expanAlert        = $EXPANALERT;
\$sleep             = $SLEEP;
\$theHoldtime       = $HOLDTIME;
\$cronInt           = $CRONINT;

// Raspberry Pi temperature alarms
\$piAlarms = $piAlarms;
\$soft     = $piSoftTemp;   // Soft warning temperature
\$hot      = $piHotTemp;    // Critical temperature
?>
EOF

log "config.php written successfully."

# ------------------------------------------------------------
# Install Cron Job
# ------------------------------------------------------------
log "Installing cron job..."

CRON_FILE="/etc/cron.d/cap-warn"
echo "2-59/$CRONINT * * * * root /usr/bin/cap-warn/cap_warn.sh >> /var/log/cap-warn/cron.log 2>&1" > "$CRON_FILE"
chmod 644 "$CRON_FILE"
chown root:root "$CRON_FILE"

log "Cron job installed via /etc/cron.d/cap-warn."

# ------------------------------------------------------------
# Log Rotation
# ------------------------------------------------------------
log "Configuring logrotate..."



cat > /etc/logrotate.d/cap-warn <<EOF
/var/log/cap-warn/*.log {
    daily
    rotate 14
    compress
    missingok
    notifempty
    # no create — CAP-Warn will create logs itself
}
EOF

log "Logrotate configured."

whiptail --title "Installation Complete" \
--msgbox "\
CAP-Warn is now fully configured.

Cron will run the alert processor every $CRONINT minutes.
Previous configuration backup:
$BACKUP

Edited $INSTALLER_VERSION Times

Press OK to finish." 15 70
log "Displayed installation complete message."

echo ""
echo "============================================================"
echo " CAP-Warn Installation Complete"
echo "------------------------------------------------------------"
echo "System: $piVersion"
echo "Edited $INSTALLER_VERSION times"
echo "You can run CAP-Warn manually at any time using:"
echo " cd /usr/bin/cap-warn/cap_warn.sh"
echo " "
echo "Running it manually will preload all data immediately."
echo ""
echo "As they used to say back in the '60s:"
echo "   \"Keep on truckin'... the weather waits for no one.\""
echo "============================================================"
echo ""

log "===== INSTALLER COMPLETE ====="
