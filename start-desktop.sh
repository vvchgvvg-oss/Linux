#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${VNC_PASSWORD:-}" ]]; then
  echo "VNC_PASSWORD is required. Copy .env.example to .env and set it." >&2
  exit 1
fi
if [[ ${#VNC_PASSWORD} -ne 8 || ! "$VNC_PASSWORD" =~ ^[A-Za-z0-9]{8}$ ]]; then
  echo "VNC_PASSWORD must be exactly 8 ASCII letters/digits (TigerVNC authentication limit)." >&2
  exit 1
fi
if [[ "$VNC_PASSWORD" == "12345678" || "$VNC_PASSWORD" == "password" || "$VNC_PASSWORD" == "REPLACE0" ]]; then
  echo "Choose a private VNC password; the example value is not secure." >&2
  exit 1
fi

mkdir -p "$HOME/.vnc" "$HOME/.config/xfce4" "$HOME/Desktop" "$HOME/Downloads" "$HOME/Documents"
chmod 700 "$HOME/.vnc"
printf '%s\n' "$VNC_PASSWORD" | vncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"

if [[ ! -f "$HOME/.vnc/xstartup" ]]; then
  cat > "$HOME/.vnc/xstartup" <<'XSTARTUP'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
startxfce4 &
SESSION_PID=$!
sleep 5
xfconf-query -c xsettings -p /Net/ThemeName --create -t string -s Windows-10 || true
xfconf-query -c xsettings -p /Net/IconThemeName --create -t string -s Windows-10 || true
xfconf-query -c xfwm4 -p /general/theme --create -t string -s Windows-10 || true
xfconf-query -c xsettings -p /Xft/DPI --create -t int -s 135 || true
xfconf-query -c xsettings -p /Gtk/FontName --create -t string -s 'Noto Sans 12' || true
xfconf-query -c xfwm4 -p /general/use_compositing --create -t bool -s false || true
xfconf-query -c xsettings -p /Gtk/CursorThemeName --create -t string -s Windows-10 || true
xfconf-query -c xfce4-desktop -l 2>/dev/null | grep '/last-image$' | while IFS= read -r property; do
  xfconf-query -c xfce4-desktop -p "$property" -s /usr/share/backgrounds/custom.jpg || true
done
wait "$SESSION_PID"
XSTARTUP
  chmod 700 "$HOME/.vnc/xstartup"
fi

touch "$HOME/.Xauthority"
vncserver :1 -localhost yes -rfbport 5901 -geometry "${VNC_GEOMETRY:-1280x720}" -depth 24 \
  -SecurityTypes VncAuth -PasswordFile "$HOME/.vnc/passwd"

# VNC is reachable only by the private Compose network; the gateway requires HTTP Basic Auth.
exec websockify --web=/usr/share/novnc/ 6080 127.0.0.1:5901
