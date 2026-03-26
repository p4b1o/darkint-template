#!/bin/bash

###############################################################################
# SPRAWDZENIE XFCE
###############################################################################
# Sprawdź czy XFCE jest zainstalowane (działa też przez SSH)
if ! command -v xfconf-query &>/dev/null; then
    echo "Blad: xfconf-query nie znaleziony. Zainstaluj XFCE przed uruchomieniem skryptu."
    exit 1
fi

echo "XFCE wykryte. Rozpoczynanie instalacji..."

###############################################################################
# NAPRAWA LOCALE
###############################################################################
echo "[1/9] Naprawa locale..."
sudo sed -i '/^# *en_US.UTF-8/s/^# *//' /etc/locale.gen 2>/dev/null || true
sudo locale-gen en_US.UTF-8 2>/dev/null || true

###############################################################################
# AKTUALIZACJA I CZYSZCZENIE
###############################################################################
echo "[2/9] Aktualizacja systemu..."
sudo apt clean
sudo apt update && sudo apt upgrade -y

###############################################################################
# INSTALACJA PODSTAWOWYCH NARZEDZI
###############################################################################
echo "[3/9] Instalacja podstawowych narzedzi..."
sudo apt install -y wget curl git build-essential python3-pip flatpak unzip python3-venv xsettingsd gnome-themes-extra adwaita-icon-theme

# Naprawa EXTERNALLY-MANAGED dla dowolnej wersji Python 3
EXTERNALLY_MANAGED=$(find /usr/lib/python3* -name "EXTERNALLY-MANAGED" 2>/dev/null | head -1)
if [ -n "$EXTERNALLY_MANAGED" ]; then
    sudo rm "$EXTERNALLY_MANAGED"
fi

###############################################################################
# INSTALACJA I KONFIGURACJA pipx
###############################################################################
echo "[4/9] Konfiguracja pipx..."
sudo apt install -y pipx
pipx ensurepath
export PATH="$HOME/.local/bin:$PATH"

###############################################################################
# KONFIGURACJA XFCE - MOTYW CIEMNY
###############################################################################
echo "[5/9] Konfiguracja XFCE..."

# Ciemny motyw XFCE - xfconf
xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-dark" --create -t string 2>/dev/null || true
xfconf-query -c xsettings -p /Net/IconThemeName -s "Adwaita" --create -t string 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/theme -s "Adwaita-dark" --create -t string 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/title_alignment -s "center" --create -t string 2>/dev/null || true

# GTK-3 dark theme (plik konfiguracyjny - dziala niezaleznie od xfconf)
mkdir -p ~/.config/gtk-3.0
cat > ~/.config/gtk-3.0/settings.ini << 'GTKCONFIG'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Adwaita
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-application-prefer-dark-theme=1
GTKCONFIG

# GTK-2 dark theme
cat > ~/.gtkrc-2.0 << 'GTK2CONFIG'
gtk-theme-name="Adwaita-dark"
gtk-icon-theme-name="Adwaita"
gtk-font-name="Sans 10"
GTK2CONFIG

###############################################################################
# TLO PULPITU XFCE
###############################################################################
echo "Pobieranie i ustawianie tla pulpitu..."

# Pobranie tla z GitHub repo
wget -q -O "$HOME/desktop.png" "https://raw.githubusercontent.com/p4b1o/darkint-template/main/desktop.png" 2>/dev/null || {
    echo "Nie udalo sie pobrac tla z GitHub."
}

if [ -f "$HOME/desktop.png" ]; then
    # Ustaw tapete na wszystkich istniejacych properties
    for PROP in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep "last-image"); do
        xfconf-query -c xfce4-desktop -p "$PROP" -s "$HOME/desktop.png" 2>/dev/null || true
    done
    for PROP in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep "image-path"); do
        xfconf-query -c xfce4-desktop -p "$PROP" -s "$HOME/desktop.png" 2>/dev/null || true
    done
    for PROP in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep "image-style"); do
        xfconf-query -c xfce4-desktop -p "$PROP" -s 5 2>/dev/null || true
    done

    # Wykryj prawdziwa nazwe monitora z xrandr i ustaw tapete
    MONITOR_NAME=$(xrandr --query 2>/dev/null | grep " connected" | head -1 | awk '{print $1}')
    if [ -n "$MONITOR_NAME" ]; then
        xfconf-query -c xfce4-desktop -p "/backdrop/screen0/monitor${MONITOR_NAME}/workspace0/last-image" \
            -s "$HOME/desktop.png" --create -t string 2>/dev/null || true
        xfconf-query -c xfce4-desktop -p "/backdrop/screen0/monitor${MONITOR_NAME}/workspace0/image-style" \
            -s 5 --create -t int 2>/dev/null || true
        xfconf-query -c xfce4-desktop -p "/backdrop/screen0/monitor${MONITOR_NAME}/workspace0/image-show" \
            -s true --create -t bool 2>/dev/null || true
    fi

    echo "Tapeta ustawiona."
fi

# Skrypt autostartu tapety - wykrywa monitor dynamicznie (RDP/VNC/lokalna konsola)
mkdir -p ~/bin
cat > ~/bin/set-wallpaper << 'SETWALLPAPER'
#!/bin/bash
sleep 3
MONITOR=$(xrandr --query 2>/dev/null | grep " connected" | head -1 | awk '{print $1}')
if [ -n "$MONITOR" ] && [ -f "$HOME/desktop.png" ]; then
    xfconf-query -c xfce4-desktop -p "/backdrop/screen0/monitor${MONITOR}/workspace0/last-image" \
        -s "$HOME/desktop.png" --create -t string 2>/dev/null
    xfconf-query -c xfce4-desktop -p "/backdrop/screen0/monitor${MONITOR}/workspace0/image-style" \
        -s 5 --create -t int 2>/dev/null
    xfconf-query -c xfce4-desktop -p "/backdrop/screen0/monitor${MONITOR}/workspace0/image-show" \
        -s true --create -t bool 2>/dev/null
    xfdesktop --quit 2>/dev/null
    sleep 1
    xfdesktop &
fi
SETWALLPAPER
chmod +x ~/bin/set-wallpaper

mkdir -p ~/.config/autostart
cat > ~/.config/autostart/set-wallpaper.desktop << 'WPDESKTOP'
[Desktop Entry]
Type=Application
Name=Set Wallpaper
Exec=/home/darkint/bin/set-wallpaper
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
WPDESKTOP

# Ustawienia panelu XFCE - ukrycie, minimalistyczny
xfconf-query -c xfce4-panel -p /panels/panel-1/autohide -s true 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/position -s "p=6;x=0;y=0" 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/size -s 28 2>/dev/null || true

# Aktualizacja cache ikon
sudo update-desktop-database 2>/dev/null || true

# Wylaczenie suspend
sudo systemctl mask suspend.target

###############################################################################
# OCHRONA ROUTINGU LAN (przed VPN)
###############################################################################
echo "Konfiguracja ochrony routingu LAN..."

cat <<'LANROUTE' | sudo tee /usr/local/bin/lan-route-protect >/dev/null
#!/bin/bash
# Chroni routing LAN przed przejciem przez VPN
LAN_IF=$(ip route | grep 'default' | head -1 | awk '{print $5}')
LAN_GW=$(ip route | grep 'default' | head -1 | awk '{print $3}')
LAN_NET=$(ip -4 addr show $LAN_IF 2>/dev/null | grep inet | awk '{print $2}')

if [ -n "$LAN_IF" ] && [ -n "$LAN_GW" ] && [ -n "$LAN_NET" ]; then
    LAN_SUBNET=$(echo $LAN_NET | cut -d'/' -f1 | sed 's/\.[0-9]*$/.0/')/24
    LAN_IP=$(echo $LAN_NET | cut -d'/' -f1)
    ip route replace $LAN_SUBNET dev $LAN_IF src $LAN_IP metric 50 2>/dev/null
    ip rule add to $LAN_SUBNET table main prio 100 2>/dev/null
    echo "LAN protected: $LAN_SUBNET via $LAN_IF (gw $LAN_GW)"
else
    echo "Could not detect LAN config"
fi

# Dodatkowe podsieci LAN
if [ -n "$LAN_IF" ] && [ -n "$LAN_GW" ]; then
    ip route replace 10.10.68.0/24 via $LAN_GW dev $LAN_IF metric 50 2>/dev/null
    ip rule add to 10.10.68.0/24 table main prio 100 2>/dev/null
    echo "Extra LAN protected: 10.10.68.0/24 via $LAN_GW"
fi
LANROUTE
sudo chmod +x /usr/local/bin/lan-route-protect

cat <<'LANSERVICE' | sudo tee /etc/systemd/system/lan-route-protect.service >/dev/null
[Unit]
Description=Protect LAN routing from VPN override
After=network-online.target
Before=AmneziaVPN.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/lan-route-protect
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
LANSERVICE

sudo systemctl daemon-reload
sudo systemctl enable lan-route-protect

###############################################################################
# INSTALACJA XRDP (PRACA ZDALNA RDP)
###############################################################################
echo "[6/9] Instalacja xrdp (dostep RDP)..."

sudo apt install -y xrdp
sudo systemctl enable xrdp

# Konfiguracja xrdp do uzywania XFCE
echo "xfce4-session" > ~/.xsession
chmod +x ~/.xsession

# Upewnienie sie ze polkit nie blokuje sesji
cat <<'POLKIT' | sudo tee /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla >/dev/null
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
POLKIT

# Konfiguracja xrdp - port i bezpieczenstwo
sudo sed -i 's/^port=.*/port=3389/' /etc/xrdp/xrdp.ini 2>/dev/null || true
sudo sed -i 's/^#\?max_bpp=.*/max_bpp=32/' /etc/xrdp/xrdp.ini 2>/dev/null || true

# Konfiguracja startwm do uruchamiania XFCE
if ! grep -q "xfce4-session" /etc/xrdp/startwm.sh 2>/dev/null; then
    sudo sed -i '/^test -x/i # Uruchom XFCE\nstartxfce4\nexit 0' /etc/xrdp/startwm.sh 2>/dev/null || true
fi

# Dodanie uzytkownika do grupy ssl-cert (wymagane przez xrdp)
sudo adduser "$USER" ssl-cert 2>/dev/null || true

sudo systemctl restart xrdp

echo "xrdp zainstalowany. Polacz sie przez RDP na port 3389."

###############################################################################
# INSTALACJA USLUGI TOR Z SOCKS PROXY
###############################################################################
echo "[7/9] Instalacja i konfiguracja uslugi Tor..."

sudo apt install -y tor

# Konfiguracja Tor - SOCKS Proxy na 9050
sudo mkdir -p /etc/tor/torrc.d
cat <<'TORCONFIG' | sudo tee /etc/tor/torrc.d/socks.conf >/dev/null
# Socks Settings
SocksPort 127.0.0.1:9050
SocksListenAddress 127.0.0.1

# Privacy settings
ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy
ClientTransportPlugin meek exec /usr/bin/meek-client
ClientTransportPlugin meek_lite exec /usr/bin/meek-client

# DNS
DNSRequestForwarding 1

# Log files
Log notice file /var/log/tor/notices.log

# Cache directory
CacheDir /var/lib/tor/cache
DataDirectory /var/lib/tor

# Default bridge
# Uncomment and modify for bridge access
# Bridge obfs4 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx cert=xxxxxxxxxxxx iat-mode=0
TORCONFIG

sudo mkdir -p /var/lib/tor
sudo systemctl daemon-reload
sudo systemctl enable tor

echo "Usluga Tor skonfigurowana. Port SOCKS: 127.0.0.1:9050"

###############################################################################
# INSTALACJA KLEOPATRA (GPG MANAGEMENT)
###############################################################################
echo "Instalacja narzedzi kryptograficznych..."

sudo apt install -y gnupg2 gnupg-agent scdaemon dirmngr kleopatra

# Wygenerowanie domyslnego configu GPG
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

###############################################################################
# INSTALACJA KEEPASSXC (MENEDZER HASEL)
###############################################################################
sudo apt install -y keepassxc

###############################################################################
# INSTALACJA APPS - Flatpak
###############################################################################
echo "[8/9] Instalacja aplikacji (Flatpak)..."

# Dodanie repozytorium Flathub jesli brak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# Obsidian
sudo flatpak install flathub md.obsidian.Obsidian -y --noninteractive

# Cryptomator
sudo flatpak install flathub org.cryptomator.Cryptomator -y --noninteractive

# Monero GUI
sudo flatpak install flathub org.getmonero.Monero -y --noninteractive

# Session
sudo flatpak install flathub network.loki.Session -y --noninteractive

# OnionShare
sudo flatpak install flathub org.onionshare.OnionShare -y --noninteractive

# Tor Browser
sudo flatpak install flathub org.torproject.torbrowser-launcher -y --noninteractive

# Zaktualizuj cache ikon (wapliwa dla Flatpak)
sudo update-desktop-database 2>/dev/null || true
flatpak update 2>/dev/null || true

###############################################################################
# INSTALACJA AMNEZIA VPN
###############################################################################
echo "Instalacja Amnezia VPN..."

cd /tmp

# Pobranie instalatora Amnezia (plik .tar, nie .tar.gz)
AMNEZIA_URL="https://github.com/amnezia-vpn/amnezia-client/releases/download/4.8.14.5/AmneziaVPN_4.8.14.5_linux_x64.tar"
wget -q "$AMNEZIA_URL" -O amnezia.tar 2>/dev/null || true

if [ -f /tmp/amnezia.tar ] && [ -s /tmp/amnezia.tar ]; then
    sudo mkdir -p /tmp/amnezia-extract
    sudo tar -xf amnezia.tar -C /tmp/amnezia-extract/

    # Uruchom instalator headless (Qt Installer Framework)
    INSTALLER=$(find /tmp/amnezia-extract -name "*.bin" -type f 2>/dev/null | head -1)
    if [ -n "$INSTALLER" ]; then
        sudo chmod +x "$INSTALLER"
        sudo QT_QPA_PLATFORM=minimal "$INSTALLER" --accept-licenses --confirm-command --default-answer install 2>/dev/null
        echo "Amnezia VPN zainstalowany."
    else
        echo "UWAGA: Nie znaleziono instalatora Amnezia."
    fi

    # Wlacz serwis systemd
    sudo cp /opt/AmneziaVPN/AmneziaVPN.service /etc/systemd/system/AmneziaVPN.service 2>/dev/null || true
    sudo systemctl daemon-reload
    sudo systemctl enable AmneziaVPN
    sudo systemctl start AmneziaVPN

    # Autostart klienta GUI przy logowaniu
    mkdir -p ~/.config/autostart
    cat > ~/.config/autostart/AmneziaVPN.desktop << 'DEOF'
[Desktop Entry]
Type=Application
Name=AmneziaVPN
Exec=/usr/local/bin/AmneziaVPN
Icon=/opt/AmneziaVPN/AmneziaVPN.png
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
DEOF

    rm -f /tmp/amnezia.tar
    sudo rm -rf /tmp/amnezia-extract
    echo "Amnezia VPN zainstalowany i wlaczony przy starcie."
else
    echo "UWAGA: Nie udalo sie pobrac Amnezia VPN."
    echo "Sprobuj manualnie: $AMNEZIA_URL"
fi
cd ~

###############################################################################
# INSTALACJA BRAVE BROWSER
###############################################################################
echo "Instalacja Brave Browser..."

sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
    | sudo tee /etc/apt/sources.list.d/brave-browser-release.list >/dev/null

sudo apt update
sudo apt install -y brave-browser

###############################################################################
# INSTALACJA THUNDERBIRD Z GPG SUPPORT
###############################################################################
echo "Instalacja Thunderbird..."

sudo apt install -y thunderbird


###############################################################################
# OPSEC MONITOR - IP I KRAJ W PROMPCIE
###############################################################################
echo "Konfiguracja OPSEC monitora IP..."

# Skrypt odpytuje ifconfig.io co 30s i cachuje wynik
cat <<'OPSECSCRIPT' | sudo tee /usr/local/bin/opsec-monitor >/dev/null
#!/bin/bash
CACHE_FILE="/tmp/.opsec-ip"
while true; do
    DATA=$(curl -s --connect-timeout 5 https://ifconfig.io/all.json 2>/dev/null)
    if [ -n "$DATA" ]; then
        IP=$(echo "$DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('ip','?'))" 2>/dev/null)
        COUNTRY=$(echo "$DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('country_code','?'))" 2>/dev/null)
        if [ -n "$IP" ] && [ "$IP" != "?" ]; then
            echo "${COUNTRY:-??}|${IP}" > "$CACHE_FILE"
        else
            echo "??|UNKNOWN" > "$CACHE_FILE"
        fi
    else
        echo "!!|NO CONNECTION" > "$CACHE_FILE"
    fi
    sleep 30
done
OPSECSCRIPT
sudo chmod +x /usr/local/bin/opsec-monitor

# Serwis systemd
cat <<'OPSECSERVICE' | sudo tee /etc/systemd/system/opsec-monitor.service >/dev/null
[Unit]
Description=OPSEC IP Monitor
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/opsec-monitor
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
OPSECSERVICE

sudo systemctl daemon-reload
sudo systemctl enable opsec-monitor
sudo systemctl start opsec-monitor

# Prompt bash - wyswietla [KRAJ IP] na zielono, lub ostrzezenie na czerwono
mkdir -p ~/.bashrc.d
cat <<'OPSECPROMPT' > ~/.bashrc.d/opsec-prompt.sh
_opsec_ps1() {
    local CACHE="/tmp/.opsec-ip"
    if [ -f "$CACHE" ]; then
        local DATA=$(cat "$CACHE" 2>/dev/null)
        local COUNTRY=$(echo "$DATA" | cut -d"|" -f1)
        local IP=$(echo "$DATA" | cut -d"|" -f2)
        if [ "$COUNTRY" = "!!" ]; then
            printf "\001\033[1;37;41m\002 !! NO CONNECTION !! \001\033[0m\002"
        else
            printf "\001\033[0;32m\002[%s %s]\001\033[0m\002" "$COUNTRY" "$IP"
        fi
    else
        printf "\001\033[1;33m\002[...]\001\033[0m\002"
    fi
}
PS1='$(_opsec_ps1) \[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
OPSECPROMPT

# Ladowanie bashrc.d
if ! grep -q "bashrc.d" ~/.bashrc 2>/dev/null; then
    cat <<'LOADRC' >> ~/.bashrc

# Load custom configs
for f in ~/.bashrc.d/*.sh; do
    [ -r "$f" ] && source "$f"
done
LOADRC
fi

###############################################################################
# STWORZENIE SKRYPTU HELPERA "dint"
###############################################################################
echo "Tworzenie skryptu dint..."

mkdir -p ~/bin

cat > ~/bin/dint << 'HELPERS'
#!/bin/bash

COMMAND="$1"

case "$COMMAND" in
    check-ip)
        echo "Sprawdzanie IP..."
        IP=$(curl -s https://api.ipify.org 2>/dev/null)
        COUNTRY=$(curl -s https://ipapi.co/$IP/country/ 2>/dev/null)
        echo "IP: ${IP:-UNKNOWN}"
        echo "Country: ${COUNTRY:-UNKNOWN}"
        ;;
    help)
        cat << 'HELP'
DarkInt Security Workstation - Helper Commands

USAGE:
  dint <command>

COMMANDS:
  start-tor       - Uruchom usluge Tor
  stop-tor        - Zamknij usluge Tor
  status-tor      - Sprawdz status Tor
  start-session   - Uruchom Session Messenger
  start-monero    - Uruchom Monero GUI Wallet
  start-amnezia   - Uruchom Amnezia VPN
  backup-keys     - Backup kluczy GPG
  check-ip        - Pokaz aktualne IP i kraj
  help            - Pokaz te pomoc
HELP
        ;;
    start-tor)
        echo "Uruchamianie uslugi Tor..."
        sudo systemctl start tor
        echo "Tor uruchomiony. SOCKS proxy: 127.0.0.1:9050"
        ;;
    stop-tor)
        echo "Zatrzymywanie uslugi Tor..."
        sudo systemctl stop tor
        echo "Tor zatrzymany."
        ;;
    status-tor)
        sudo systemctl status tor
        ;;
    start-session)
        echo "Uruchamianie Session..."
        flatpak run network.loki.Session &
        ;;
    start-monero)
        echo "Uruchamianie Monero GUI..."
        flatpak run org.getmonero.Monero &
        ;;
    start-amnezia)
        echo "Uruchamianie Amnezia VPN..."
        if [ -x /usr/local/bin/AmneziaVPN ]; then
            /usr/local/bin/AmneziaVPN &
        else
            echo "Amnezia VPN nie znaleziony."
        fi
        ;;
    backup-keys)
        echo "Backup kluczy GPG..."
        mkdir -p ~/darkint/backup
        gpg --export --armor > ~/darkint/backup/public-$(date +%Y%m%d).asc
        gpg --export-secret-keys --armor > ~/darkint/backup/private-$(date +%Y%m%d).asc
        echo "Zapisano do: ~/darkint/backup/"
        ;;
    *)
        echo "DarkInt Helpers - uzyj 'dint help' po liste komend"
        ;;
esac
HELPERS

chmod +x ~/bin/dint

# Dodaj ~/bin do PATH jesli nie ma
if ! grep -q 'PATH="$HOME/bin:$PATH"' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
fi

###############################################################################
# KONFIGURACJA PANELU DOLNEGO (DOCK) Z LAUNCHERAMI
###############################################################################
echo "[9/9] Konfiguracja panelu dolnego z programami..."

# Panel 2 to dock na dole - zamien domyslne launchery na nasze programy
# 15 = Brave (zamiast generycznej przegladarki)
LAUNCHER15_FILE=$(ls ~/.config/xfce4/panel/launcher-15/*.desktop 2>/dev/null | head -1)
if [ -n "$LAUNCHER15_FILE" ]; then
    cat > "$LAUNCHER15_FILE" << 'DEOF'
[Desktop Entry]
Type=Application
Name=Brave Browser
Exec=brave-browser %U
Icon=brave-browser
Terminal=false
Categories=Network;WebBrowser;
DEOF
fi

# 16 = Thunderbird (zamiast appfindera)
LAUNCHER16_FILE=$(ls ~/.config/xfce4/panel/launcher-16/*.desktop 2>/dev/null | head -1)
if [ -n "$LAUNCHER16_FILE" ]; then
    cat > "$LAUNCHER16_FILE" << 'DEOF'
[Desktop Entry]
Type=Application
Name=Thunderbird
Exec=thunderbird %u
Icon=thunderbird
Terminal=false
Categories=Network;Email;
DEOF
fi

# Nowe launchery: 19-26
NEXT_ID=19

create_launcher() {
    local ID=$1 NAME=$2 EXEC=$3 ICON=$4
    local DIR="$HOME/.config/xfce4/panel/launcher-$ID"
    local FILENAME=$(echo "$NAME" | tr '[:upper:] ' '[:lower:]-').desktop
    mkdir -p "$DIR"
    cat > "$DIR/$FILENAME" << DEOF
[Desktop Entry]
Type=Application
Name=$NAME
Exec=$EXEC
Icon=$ICON
Terminal=false
DEOF
    xfconf-query -c xfce4-panel -p /plugins/plugin-$ID -s "launcher" --create -t string 2>/dev/null
    xfconf-query -c xfce4-panel -p /plugins/plugin-$ID/items -a -s "$FILENAME" --create -t string 2>/dev/null
}

create_launcher 19 "KeePassXC"   "keepassxc %f"                          "/usr/share/icons/hicolor/256x256/apps/keepassxc.png"
create_launcher 20 "Kleopatra"   "kleopatra"                              "/usr/share/icons/hicolor/48x48/apps/kleopatra.png"
create_launcher 21 "Obsidian"    "flatpak run md.obsidian.Obsidian"       "md.obsidian.Obsidian"
create_launcher 22 "Session"     "flatpak run network.loki.Session"       "network.loki.Session"
create_launcher 23 "Monero GUI"  "flatpak run org.getmonero.Monero"       "org.getmonero.Monero"
create_launcher 24 "Cryptomator" "flatpak run org.cryptomator.Cryptomator" "org.cryptomator.Cryptomator"
create_launcher 25 "OnionShare"  "flatpak run org.onionshare.OnionShare"  "org.onionshare.OnionShare"
create_launcher 26 "Amnezia VPN" "/usr/local/bin/AmneziaVPN"              "AmneziaVPN"
create_launcher 27 "Tor Browser" "flatpak run org.torproject.torbrowser-launcher" "org.torproject.torbrowser-launcher"

# Zaktualizuj liste pluginow panelu 2 (kolejnosc: showdesktop, sep, Terminal, FileManager, Brave, TorBrowser, Thunderbird, KeePassXC, Kleopatra, Obsidian, Session, Monero, Cryptomator, OnionShare, Amnezia, sep, directorymenu)
xfconf-query -c xfce4-panel -p /panels/panel-2/plugin-ids \
    -s 11 -s 12 -s 13 -s 14 -s 15 -s 27 -s 16 -s 19 -s 20 -s 21 -s 22 -s 23 -s 24 -s 25 -s 26 -s 17 -s 18 2>/dev/null

# Panel 2 widoczny (nie autohide)
xfconf-query -c xfce4-panel -p /panels/panel-2/autohide-behavior -s 0 2>/dev/null || true

###############################################################################
# FINISH
###############################################################################
echo ""
echo "========================================="
echo "  DarkInt Security Workstation Ready!"
echo "========================================="
echo ""
echo "Zainstalowane aplikacje:"
echo "  Tor Browser - przegladarka z anononimizacja"
echo "  Brave - przegladarka z blokada trackingu"
echo "  Thunderbird z GPG - bezpieczna poczta"
echo "  Kleopatra - menedzer kluczy GPG"
echo "  KeePassXC - menedzer hasel"
echo "  Cryptomator - szyfrowanie plikow"
echo "  Monero GUI - anonimowa kryptowaluta"
echo "  Session - zdecentralizowany messenger"
echo "  OnionShare - bezpieczne udostepnianie"
echo "  Obsidian - notatnik"
echo "  Amnezia VPN - szyfrowane tunele"
echo "  Usluga Tor z SOCKS proxy (9050)"
echo "  xrdp - dostep RDP na porcie 3389"
echo ""
echo "Programy dostepne na dolnym panelu (dock):"
echo "  Brave Browser | Tor Browser | Thunderbird | KeePassXC | Kleopatra"
echo "  Obsidian | Session | Monero GUI | Cryptomator | OnionShare | Amnezia VPN"
echo "Przydatne komendy:"
echo "  dint help      - Pokaz pomoc"
echo "  dint check-ip  - Sprawdz IP"
echo ""
echo "Dostep zdalny:"
echo "  RDP: $(hostname -I 2>/dev/null | awk '{print $1}'):3389"
echo ""
echo "UWAGA: Wyloguj sie i zaloguj ponownie aby zastosowac motyw ciemny."
echo ""
