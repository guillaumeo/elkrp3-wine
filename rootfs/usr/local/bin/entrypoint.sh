#!/usr/bin/env bash
set -euo pipefail

cp -an /opt/elkrp-db-seed/. /database/
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 /tmp/vnc.sock

Xvfb "${DISPLAY}" -screen 0 1440x900x24 -ac +extension GLX +render -noreset &
for _ in $(seq 1 30); do
  if [ -S /tmp/.X11-unix/X1 ]; then break; fi
  sleep 0.2
done
if [ ! -S /tmp/.X11-unix/X1 ]; then
  echo "ERROR: Xvfb failed to start on ${DISPLAY}" >&2
  exit 1
fi

openbox &
tint2 -c /etc/xdg/tint2/tint2rc &
x11vnc -display "${DISPLAY}" -unixsock /tmp/vnc.sock -rfbport 0 -forever -shared -nopw -quiet &
/usr/local/bin/launch-elkrp >/dev/null 2>&1 &

exec websockify --web /usr/share/novnc --unix-target=/tmp/vnc.sock 3000
