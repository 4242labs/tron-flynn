#!/bin/bash
# tron-flynn PULSE guard (Stop hook).
# No-op unless a flynn run is active (.tron-flynn-active flag in project root).
# Blocks turn end if the PULSE timer has lapsed, forcing flynn to re-arm.

input=$(cat)
flag=".tron-flynn-active"

[ -f "$flag" ] || exit 0

# Already blocked once this stop — let it through to avoid an infinite loop.
echo "$input" | grep -q '"stop_hook_active":true' && exit 0

armed_until=$(cat "$flag" 2>/dev/null)
case "$armed_until" in ('' | *[!0-9]*) armed_until=0 ;; esac

now=$(date +%s)
if [ "$now" -gt "$armed_until" ]; then
  echo "PULSE not armed or lapsed. Arm the background timer now (sleep 180, run_in_background) and write the new expiry to the flag: echo \$(( \$(date +%s) + 240 )) > .tron-flynn-active — then continue the run." >&2
  exit 2
fi

exit 0
