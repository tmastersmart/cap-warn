#!/bin/bash
# net-flag  (c) KJ5MZL
# simple link/net suppression flag
# creates /tmp/linked_true.txt when ON
# Call from cron with on off toggle
FLAG="/tmp/linked_true.txt"

case "$1" in
 on)
  touch "$FLAG"
  echo "net-flag: ON (hub muted)"
 ;;
 off)
  rm -f "$FLAG"
  echo "net-flag: OFF (normal)"
 ;;
 toggle)
  if [ -f "$FLAG" ]; then
   rm -f "$FLAG"
   echo "net-flag: toggled OFF"
  else
   touch "$FLAG"
   echo "net-flag: toggled ON"
  fi
 ;;
 status)
  if [ -f "$FLAG" ]; then
   echo "net-flag: ON"
  else
   echo "net-flag: OFF"
  fi
 ;;
 *)
  echo "usage: $0 {on|off|toggle|status}"
  exit 1
 ;;
esac
