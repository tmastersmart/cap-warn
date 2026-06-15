#!/bin/bash
cd /usr/share/cap-warn

echo ""
echo "============================================================"
echo " CAP-WARN SETUP — TEXT MODE HELP"
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





# ------------------------------------------------------------
# Detect if config.php is valid before loading
# ------------------------------------------------------------
CONFIG="/etc/cap-warn/config.php"

LOAD_OLD=false

if [ -f "$CONFIG" ]; then
    # Try reading the first variable safely
    TESTVAL=$(php -r "include '$CONFIG'; echo isset(\$node) ? 'OK' : 'BAD';" 2>/dev/null)

    if [ "$TESTVAL" = "OK" ]; then
        LOAD_OLD=true
        log "Existing config.php is valid. Loading previous values."
    else
        log "Existing config.php is invalid or empty. Skipping load."
    fi
else
    log "No config.php found. Fresh install."
fi




if [ "$LOAD_OLD" = true ]; then
    OLD_NODE=$(php -r "include '$CONFIG'; echo \$node ?? '';")
    OLD_TTS=$(php -r "include '$CONFIG'; echo \$tts ?? '';")
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
else
    # Fresh install defaults
    OLD_NODE=""
    OLD_TTS=""
    OLD_LAT=""
    OLD_LON=""
    OLD_STORMRADIUS="1000"
    OLD_DETECTCYCLONE="false"
    OLD_CYURL="disabled"
    OLD_EXPANALERT="true"
    OLD_SEXPANALERT="false"
    OLD_SLEEP="false"
    OLD_HOLDTIME="25"
    OLD_CRONINT="13"
    OLD_PIALARMS="false"
    OLD_SOFT="65"
    OLD_HOT="75"
    OLD_HURONLY="false"
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

echo ""
echo "CAP-WARN SETUP"
echo "---------------"

read -p "Enter VoiceRSS API Key (blank = offline TTS)[$OLD_TTS]: " TTSKEY
TTS=${TTS:-$OLD_TTS}
log "TTS key: $TTS"

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


echo ""
echo "============================================================"
echo " CAP-WARN CONFIGURATION SUMMARY"
echo "============================================================"
echo "Node Number:          $NODE"
echo "Latitude:             $LAT"
echo "Longitude:            $LON"
echo "VoiceRSS Key:         ${TTS:-None (offline TTS)}"
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
\$node="$NODE";
\$tts="$TTS";
\$lat="$LAT";
\$lon="$LON";
\$stormRadiusMiles=$STORMRADIUS;
\$detectCyclone=$DETECTCYCLONE;
\$cycloneURL="$CYURL";
\$hurOnly=$REPORT_HURRICANE_ONLY;
\$expanAlert=$EXPANALERT;
\$specialExpand     = $SEXPANALERT;
\$sleep=$SLEEP;
\$theHoldtime=$HOLDTIME;
\$cronInt=$CRONINT;
\$piAlarms=$piAlarms;
\$soft=$piSoftTemp;
\$hot=$piHotTemp;
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
