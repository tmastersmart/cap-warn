#!/bin/bash
cd /usr/share/cap-warn

echo ""
echo "============================================================"
echo " CAP-WARN SETUP — TEXT MODE HELP v2"
echo "============================================================"
echo ""
echo "This setup program will guide you through configuring:"
echo ""
echo " • Your AllStar node number"
echo " • Latitude / Longitude (or GPS auto-detection)"
echo " • Hurricane tracking region (Atlantic, EPac, CPac, or disabled)"
echo " • Storm radius filtering"
echo " • Hurricane-only mode"
echo " • Expanded alert descriptions"
echo " • Quiet hours (1AM–6AM mute)"
echo " • Hold timer for repeated NWS alerts"
echo " • Cron interval for alert checks"
echo " • Text-to-speech engine (VoiceRSS or offline Piper/asl-tts)"
echo " • Raspberry Pi temperature/voltage alarms (Pi only)"
echo ""
echo "NOTES:"
echo " - VoiceRSS provides the best audio quality. A free API key is available."
echo " - If no key is entered, CAP-Warn will use offline TTS."
echo " - GPS, if connected, will override manual Lat/Lon once locked."
echo " - Hurricane alerts come from the National Hurricane Center (NHC)."
echo " - Storm radius applies ONLY to tropical systems, not NWS alerts."
echo " - Quiet Hours suppresses ALL audio alerts overnight."
echo " - Pi alarms are only shown on Raspberry Pi hardware."
echo ""
echo "Press ENTER to begin setup."
read


LOGDIR="/var/log/cap-warn"
LOGFILE="$LOGDIR/install.log"
sudo mkdir -p "$LOGDIR"
sudo touch "$LOGFILE"
sudo chmod 644 "$LOGFILE"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S')  $1" | sudo tee -a "$LOGFILE" >/dev/null
}



sudo mkdir -p /etc/cap-warn
sudo chmod 755 /etc/cap-warn

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

echo "Detected system: $piVersion"
log "Detected system: $piVersion"

CONFIG="/etc/cap-warn/config.php"
# ------------------------------------------------------------
# Load existing config values (if present)
# ------------------------------------------------------------
# $specialExpand=false;  // will the expanded repeat.
#    $user_key = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';  // Replace with your Pushover User Key
#    $api_token = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';  // Replace with your Pushover API Token
OLD_PUSHKEY=""
OLD_PUSHTOKEN=""
OLD_NOTIFYMODE=""
OLD_NODE=""
OLD_TTSKEY=""
OLD_LAT=""
OLD_LON=""
OLD_STORMRADIUS=""
OLD_DETECTCYCLONE=""
OLD_CYURL=""
OLD_EXPANALERT=""
OLD_SEXPANALERT="" 
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
    OLD_TTSKEY=$(php -r "include '$CONFIG'; echo \$tts ?? '';")
    OLD_LAT=$(php -r "include '$CONFIG'; echo \$lat ?? '';")
    OLD_LON=$(php -r "include '$CONFIG'; echo \$lon ?? '';")
    OLD_STORMRADIUS=$(php -r "include '$CONFIG'; echo \$stormRadiusMiles ?? '';")
    OLD_DETECTCYCLONE=$(php -r "include '$CONFIG'; echo \$detectCyclone ?? '';")
    OLD_CYURL=$(php -r "include '$CONFIG'; echo \$cycloneURL ?? '';")
    OLD_EXPANALERT=$(php -r "include '$CONFIG'; echo \$expanAlert ?? '';")
    OLD_SEXPANALERT=$(php -r "include '$CONFIG'; echo \$specialExpand ?? '';")
    OLD_SLEEP=$(php -r "include '$CONFIG'; echo \$sleep ?? '';")
    OLD_HOLDTIME=$(php -r "include '$CONFIG'; echo \$theHoldtime ?? '';")
    OLD_CRONINT=$(php -r "include '$CONFIG'; echo \$cronInt ?? '';")
    OLD_PIALARMS=$(php -r "include '$CONFIG'; echo \$piAlarms ?? '';")
    OLD_SOFT=$(php -r "include '$CONFIG'; echo \$soft ?? '';")
    OLD_HOT=$(php -r "include '$CONFIG'; echo \$hot ?? '';")
    OLD_HURONLY=$(php -r "include '$CONFIG'; echo \$hurOnly ?? '';")
    OLD_NOTIFYMODE=$(php -r "include '$CONFIG'; echo \$pushNotify?? '';")
    OLD_PUSHKEY=$(php -r "include '$CONFIG'; echo \$user_key?? '';")
    OLD_PUSHTOKEN=$(php -r "include '$CONFIG'; echo \$api_token ?? '';")
    
    
fi

# Smart defaults when missing
[ -z "$OLD_STORMRADIUS" ] && OLD_STORMRADIUS="1000"
[ -z "$OLD_HOLDTIME" ] && OLD_HOLDTIME="25"
[ -z "$OLD_CRONINT" ] && OLD_CRONINT="13"
[ -z "$OLD_SOFT" ] && OLD_SOFT="65"
[ -z "$OLD_HOT" ] && OLD_HOT="75"
[ -z "$OLD_HURONLY" ] && OLD_HURONLY="false"
[ -z "$OLD_EXPANALERT" ] && OLD_EXPANALERT="true"
[ -z "$OLD_SEXPANALERT" ] && OLD_SEXPANALERT="false"
[ -z "$OLD_DETECTCYCLONE" ] && OLD_DETECTCYCLONE="false"


# Normalize PHP boolean output for all boolean config vars
normalize_bool() {
    local val="$1"
    if [[ "$val" == "1" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

OLD_DETECTCYCLONE=$(normalize_bool "$OLD_DETECTCYCLONE")
OLD_HURONLY=$(normalize_bool "$OLD_HURONLY")
OLD_EXPANALERT=$(normalize_bool "$OLD_EXPANALERT")
OLD_SEXPANALERT=$(normalize_bool "$OLD_SEXPANALERT")
OLD_SLEEP=$(normalize_bool "$OLD_SLEEP")
OLD_PIALARMS=$(normalize_bool "$OLD_PIALARMS")



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



echo ""
echo "CAP-WARN SETUP"
echo "---------------"

read -p "Enter VoiceRSS API Key (blank = offline TTS)[$OLD_TTSKEY]: " TTSKEY
TTSKEY=${TTSKEY:-$OLD_TTSKEY}
log "TTS key: $TTSKEY"

echo ""
echo "Enter Latitude and Longitude "
read -p "Latitude 31.00  [$OLD_LAT]: " LAT
read -p "Longitude -92.00 [$OLD_LON]: " LON
LAT=${LAT:-$OLD_LAT}
LON=${LON:-$OLD_LON}

echo ""
read -p "Enter AllStar Node Number [$OLD_NODE]: " NODE
NODE=${NODE:-$OLD_NODE}

echo ""
echo "Hurricane Feed:"
echo "1 = Atlantic/Gulf"
echo "2 = Eastern Pacific"
echo "3 = Central Pacific"
echo "0 = Disable"
read -p "Select region [$OLD_CYURL]: " HF

case $HF in
    1) CYURL="/gis-at.xml"; DETECTCYCLONE=true ;;
    2) CYURL="/gis-ep.xml"; DETECTCYCLONE=true ;;
    3) CYURL="/gis-cp.xml"; DETECTCYCLONE=true ;;
    0) CYURL="disabled"; DETECTCYCLONE=false ;;
    *) CYURL="$OLD_CYURL"; DETECTCYCLONE="$OLD_DETECTCYCLONE" ;;
esac

# ------------------------------------------------------------
# Only ask storm radius + hurricane-only IF detection is enabled
# ------------------------------------------------------------
if [ "$DETECTCYCLONE" = true ]; then

    echo ""
    read -p "Storm radius miles [$OLD_STORMRADIUS]: " STORMRADIUS
    STORMRADIUS=${STORMRADIUS:-$OLD_STORMRADIUS}

    echo ""
    read -p "Hurricane only? (y/n) [$OLD_HURONLY]: " HUR
    if [[ "$HUR" =~ ^[Yy]$ ]]; then
        REPORT_HURRICANE_ONLY=true
    else
        REPORT_HURRICANE_ONLY=false
    fi

else
    # Cyclone detection disabled → force safe defaults
    STORMRADIUS=0
    REPORT_HURRICANE_ONLY=false
fi


echo ""
read -p "Expanded alert descriptions? (y/n) [$OLD_EXPANALERT]: " EA
if [[ "$EA" =~ ^[Yy]$ ]]; then
    EXPANALERT=true
else
    EXPANALERT=false
fi

echo ""
read -p "Repeate Expanded alerts? (y/n) [$SOLD_EXPANALERT]: " EA
if [[ "$EA" =~ ^[Yy]$ ]]; then
    SEXPANALERT=true
else
    SEXPANALERT=false
fi

echo ""
read -p "Enable Quiet Hours 1AM–6AM? (y/n) [$OLD_SLEEP]: " QS
if [[ "$QS" =~ ^[Yy]$ ]]; then
    SLEEP=true
else
    SLEEP=false
fi

echo ""
read -p "Hold time minutes [$OLD_HOLDTIME]: " HOLDTIME
HOLDTIME=${HOLDTIME:-$OLD_HOLDTIME}

echo ""
read -p "Cron interval minutes [$OLD_CRONINT]: " CRONINT
CRONINT=${CRONINT:-$OLD_CRONINT}

# ------------------------------------------------------------
# Raspberry Pi alarm options
# ------------------------------------------------------------
if [ "$piSystem" = true ]; then
    echo ""
    echo "Raspberry Pi detected: $piVersion"
    read -p "Enable Pi temperature/voltage alarms? (y/N): " PA

    if [[ "$PA" =~ ^[Yy]$ ]]; then
        piAlarms=true
        read -p "Soft temp warning C [$OLD_SOFT]: " piSoftTemp
        read -p "Critical temp C [$OLD_HOT]: " piHotTemp
        piSoftTemp=${piSoftTemp:-$OLD_SOFT}
        piHotTemp=${piHotTemp:-$OLD_HOT}
    else
        piAlarms=false
        piSoftTemp=$OLD_SOFT
        piHotTemp=$OLD_HOT
    fi
else
    echo ""
    echo "Non‑Pi system detected — skipping Pi alarm settings."
    piAlarms=false
    piSoftTemp=$OLD_SOFT
    piHotTemp=$OLD_HOT
fi




# Normalize booleans
[[ "$OLD_PIALARMS" == "1" ]] && OLD_PIALARMS="true"
[[ -z "$OLD_PIALARMS" ]] && OLD_PIALARMS="false"

# Ask for Pushover User Key
read -p "Enter Pushover User Key (blank to disable) [$OLD_PUSHKEY]: " PUSHKEY
[[ -z "$PUSHKEY" ]] && PUSHKEY="$OLD_PUSHKEY"

# Ask for Pushover API Token
read -p "Enter Pushover API Token (blank to disable) [$OLD_PUSHTOKEN]: " PUSHTOKEN
[[ -z "$PUSHTOKEN" ]] && PUSHTOKEN="$OLD_PUSHTOKEN"

# Decide whether to ask for notification mode
if [[ -n "$PUSHKEY" && -n "$PUSHTOKEN" ]]; then

    if [[ "$OLD_PIALARMS" == "true" ]]; then
        # Pi alarms enabled → ask user
        echo ""
        echo "Notification Mode Options:"
        echo "  1) All alerts: Voice + Pushover"
        echo "  2) Pi Temp/UV only: Voice + Pushover"
        echo "  3) Pi Temp/UV only: Pushover only"
        echo ""

        read -p "Choose notification mode [1-3] (current: $OLD_NOTIFYMODE): " MODE

        case "$MODE" in
            1) NOTIFYMODE="all" ;;
            2) NOTIFYMODE="pi_both" ;;
            3) NOTIFYMODE="pi_pushover" ;;
            *) NOTIFYMODE="$OLD_NOTIFYMODE" ;;
        esac

    else
        # Pi alarms OFF → default to ALL
        NOTIFYMODE="all"
    fi

else
    # No Pushover keys → no mode needed
    NOTIFYMODE="$OLD_NOTIFYMODE"
fi




TODAY=$(date +"%m-%d-%Y")

echo ""
echo "============================================================"
echo " CAP-WARN CONFIGURATION SUMMARY"
echo "============================================================"
echo "Node Number:          $NODE"
echo "Latitude:             $LAT"
echo "Longitude:            $LON"
echo "VoiceRSS Key:         ${TTSKEY:-(None - using offline TTS)}"
echo "Hurricane Detection:  $DETECTCYCLONE ($CYURL)"
echo "Storm Radius:         $STORMRADIUS miles"
echo "Hurricane Only:       $REPORT_HURRICANE_ONLY"
echo "Expanded Alerts:      $EXPANALERT"
echo "Repeate Exp Alerts:   $SEXPANALERT"
echo "Quiet Hours:          $SLEEP"
echo "Hold Time:            $HOLDTIME minutes"
echo "Cron Interval:        $CRONINT minutes"
echo ""
echo "Raspberry Pi Alarms:  $piAlarms"
echo "  Soft Warning:       $piSoftTemp C"
echo "  Critical Alarm:     $piHotTemp C"
echo "Pushover KEY          $PUSHKEY"
echo "Pushover TOKEN        $PUSHTOKEN"
echo "Pushover Mode         $NOTIFYMODE"
echo "============================================================"
echo ""

read -p "Save this configuration? (y/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Configuration NOT saved. Exiting without changes."
    exit 0
fi



echo "Saving configuration..."

sudo tee "$CONFIG" >/dev/null <<EOF
<?php
// ------------------------------------------------------------
// CAP-Warn Configuration File
// ------------------------------------------------------------
// This file is generated automatically by setup.sh.
// Running setup.sh again will update these values using
// your previous configuration as defaults.
//
// Experts may edit advanced_config.php for test but that may get 
// Overiden on updates it is not expected to be edited. It contains
// expert settings and will be used to set defaults for new options
//
// System detected: $piVersion
// Installer version: Text editor $INSTALLER_VERSION $TODAY
// ------------------------------------------------------------
\$editDate          = "$TODAY";
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
\$specialExpand     = $SEXPANALERT;
\$sleep             = $SLEEP;
\$theHoldtime       = $HOLDTIME;
\$cronInt           = $CRONINT;
\$user_key          = "$PUSHKEY";
\$api_token         = "$PUSHTOKEN";
\$pushNotify        = "$NOTIFYMODE"; // all pi-both pi-pushover

// Raspberry Pi temperature alarms
\$piAlarms = $piAlarms;
\$soft     = $piSoftTemp;   // Soft warning temperature
\$hot      = $piHotTemp;    // Critical temperature
?>
EOF

echo ""
echo "Cron Job Options:"
echo "1 = Install cron job"
echo "2 = Remove cron job"
echo "3 = Skip (do nothing)"
read -p "Choose an option [1/2/3]: " CRONCHOICE

case "$CRONCHOICE" in

    1)
        echo ""
        echo "Installing cron job..."
        sudo bash -c "echo \"2-59/$CRONINT * * * * root /usr/bin/cap-warn/cap_warn.sh >> /var/log/cap-warn/cron.log 2>&1\" > /etc/cron.d/cap-warn"
        sudo chmod 644 /etc/cron.d/cap-warn
        sudo chown root:root /etc/cron.d/cap-warn
        echo "Cron job installed."
        ;;

    2)
        echo ""
        echo "Removing cron job..."
        sudo rm -f /etc/cron.d/cap-warn
        echo "Cron job removed."
        ;;

    3|*)
        echo ""
        echo "Skipping cron job changes."
        ;;

esac

echo ""
echo "Configuring logrotate..."
sudo tee /etc/logrotate.d/cap-warn >/dev/null <<EOF
/var/log/cap-warn/*.log {
    daily
    rotate 14
    compress
    missingok
    notifempty
}
EOF

echo ""
echo "============================================================"
echo " CAP-WARN TEXT INSTALL COMPLETE"
echo "============================================================"
echo "Run manually with:"
echo "   /usr/bin/cap-warn/cap_warn.sh"
echo ""
