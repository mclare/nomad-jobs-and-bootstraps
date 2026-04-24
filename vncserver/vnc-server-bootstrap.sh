#!/bin/bash
set -e

echo "################################"
date
echo "################################"
echo "Starting Alpine VNC Bootstrap"

# 1. System Setup
echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories
apk update
apk add --no-cache \
    sudo bash tigervnc xfce4 xfce4-terminal firefox \
    dbus dbus-x11 ttf-dejavu adwaita-icon-theme

# 2. Create the Nomad User
if ! id -u "$VNC_USER" >/dev/null 2>&1; then
    adduser -D -s /bin/bash "$VNC_USER"
    echo "$VNC_USER:$USER_PASS" | chpasswd
    echo "$VNC_USER ALL=(ALL) ALL" > /etc/sudoers.d/$VNC_USER
fi

# 3. Setup VNC and Firefox as the specific user
sudo -u "$VNC_USER" -H bash <<EOF
    mkdir -p ~/.vnc
    
    # --- A. PASSWORD LOGIC ---
    echo "$VNC_SERVER_PASS" | vncpasswd -f > ~/.vnc/passwd
    chmod 600 ~/.vnc/passwd

    # --- B. CONFIG LOGIC ---
    cat <<EOC > ~/.vnc/config
geometry=1280x720
depth=24
localhost=no
securitytypes=VncAuth
passwordfile=/home/$VNC_USER/.vnc/passwd
EOC

    # --- D. XSTARTUP LOGIC ---
    cat <<EOX > ~/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Start the window manager
startxfce4 &

# firefox --kiosk --profile /opt/firefox-profile --new-window "http://192.168.40.11:8123/lovelace/"
EOX
    chmod +x ~/.vnc/xstartup

    # --- E. START SERVER ---
    vncserver -kill :1 2>/dev/null || true
    vncserver :1
EOF

echo "VNC server is running for $VNC_USER on :1 (Port 5901)"

# 4. Keep alive
LOG_FILE=\$(ls /home/"$VNC_USER"/.vnc/*.log 2>/dev/null | head -n 1)
if [ -z "\$LOG_FILE" ]; then
    echo "Waiting for log file..."
    sleep 5
    LOG_FILE=\$(ls /home/"$VNC_USER"/.vnc/*.log 2>/dev/null | head -n 1)
fi

exec tail -f "\$LOG_FILE"