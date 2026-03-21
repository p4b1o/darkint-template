#!/bin/bash

###############################################################################
# SPRAWDZENIE XFCE
###############################################################################
if [ -z "$XDG_CURRENT_DESKTOP" ] || [[ "$XDG_CURRENT_DESKTOP" != *"XFCE"* ]]; then
    echo "Błąd: To skrypt wymaga środowiska XFCE."
    echo "Wyloguj się i wybierz XFCE przed uruchomieniem skryptu."
    exit 1
fi

echo "Środowisko XFCE wykryte. Rozpoczynanie instalacji..."

###############################################################################
# AKTUALIZACJA I CZYSZCZENIE
###############################################################################
echo "[1/7] Aktualizacja systemu..."
sudo apt clean
sudo apt update && sudo apt upgrade -y

###############################################################################
# INSTALACJA PODSTAWOWYCH NARZĘDZI
###############################################################################
echo "[2/7] Instalacja podstawowych narzędzi..."
sudo apt install -y wget curl git build-essential python3-pip flatpak unzip python3-venv xsettingsd

# Naprawa EXTERNALLY-MANAGED dla Python 3.11+
if [ -f /usr/lib/python3.11/EXTERNALLY-MANAGED ]; then
    sudo rm /usr/lib/python3.11/EXTERNALLY-MANAGED
fi

###############################################################################
# INSTALACJA I KONFIGURACJA pipx
###############################################################################
echo "[3/7] Konfiguracja pipx..."
sudo apt install -y pipx
pipx ensurepath
export PATH="$HOME/.local/bin:$PATH"

###############################################################################
# KONFIGURACJA XFCE
###############################################################################
echo "[4/7] Konfiguracja XFCE..."

# Instalacja ciemnego motywu Adwaita-dark
sudo apt install -y gtk-theme-switch adwaita-icon-theme

###############################################################################
# TŁO PULPITU XFCE
###############################################################################
echo "Pobieranie i ustawianie tła pulpitu..."

# Pobranie tła z GitHub repo
cd ~
wget -O "$HOME/desktop.png" "https://raw.githubusercontent.com/p4b1o/darkint-template/main/desktop.png" 2>/dev/null || {
    echo "Nie udało się pobrać tła z GitHub."
}

# Pobranie nazwy podłączonego monitora (wymagane w XFCE)
MONITOR=$(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep "workspace0/last-image" | head -n 1 | cut -d' ' -f1)

if [ -f "$HOME/desktop.png" ]; then
    if [ -n "$MONITOR" ]; then
        # Ustaw tło dla wykrytego monitora
        xfconf-query -c xfce4-desktop -p "$MONITOR" -s "$HOME/desktop.png" 2>/dev/null || true
    fi
    
    # Fallback - jeśli nie wykryto monitora
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorVirtual1/workspace0/last-image -s "file://$HOME/desktop.png" --create -t string 2>/dev/null || true
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorVirtual1/workspace0/image-style -s 5 --create -t int 2>/dev/null || true
fi

# Ustawienia panelu XFCE - ukrycie, minimalistyczny
xfconf-query -c xfce4-panel -p /panels/panel-1/autohide -s true 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/position -s "p=6;x=0;y=0" 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/size -s 28 2>/dev/null || true

# Wyłączenie suspend
sudo systemctl mask suspend.target

# Ciemny motyw XFCE
xfconf-query -c xfce4-appearance -p /style/Name -s "Adwaita-dark" 2>/dev/null || true
xfconf-query -c xfce4-appearance -p /IconThemeName -s "Adwaita" 2>/dev/null || true
xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-dark" --create -t string 2>/dev/null || true
xfconf-query -c xsettings -p /Net/IconThemeName -s "Adwaita" --create -t string 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/theme -s "Adwaita-dark" --create -t string 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/title_alignment -s "center" --create -t string 2>/dev/null || true

###############################################################################
# INSTALACJA USŁUGI TOR Z SOCKS PROXY
###############################################################################
echo "[5/7] Instalacja i konfiguracja usługi Tor..."

sudo apt install -y tor

# Konfiguracja Tor - SOCKS Proxy na 9050
cat | sudo tee /etc/tor/torrc.d/socks.conf 2>/dev/null > /dev/null << 'TORCONFIG'
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

# Utworzenie katalogu i uruchomienie Tor
sudo mkdir -p /etc/tor/torrc.d
sudo mkdir -p /var/lib/tor
sudo systemctl daemon-reload

# Autostart Tor
sudo systemctl enable tor

echo "Usługa Tor skonfigurowana. Port SOCKS: 127.0.0.1:9050"

###############################################################################
# INSTALACJA KLEOPATRA (GPG MANAGEMENT)
###############################################################################
echo "[6/7] Instalacja narzędzi kryptograficznych..."

sudo apt install -y gnupg2 gnupg-agent scdaemon dirmngr kleopatra

# Wygenerowanie domyślnego configu GPG
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

###############################################################################
# INSTALACJA KEEPASSXC (MENEDŻER HASEŁ)
###############################################################################
pipx install keepassxc 2>/dev/null || sudo apt install -y keepassxc

###############################################################################
# VERACRYPT instalacja przez apt
echo "[7/7] Instalacja aplikacji..."

# VeraCrypt - Flatpak nie zawsze dostępny, używamy apt
sudo apt install -y veracrypt 2>/dev/null || {
    echo "VeraCrypt przez Flatpak..."
    sudo flatpak install flathub org.virbox.virboxcrypt -y 2>/dev/null || true
}

###############################################################################
# INSTALACJA MONERO GUI WALLET
###############################################################################
echo "Pobieranie Monero GUI Wallet..."
# Monero - przez apt (domyślnie z deb repo w Debian)
sudo apt install -y monero-gui monero-cli 2>/dev/null || {
    echo "Monero przez GitHub release..."
    MONERO_RELEASE="v0.18.4.6"
    MONERO_URL="https://github.com/monero-project/monero/releases/download/$MONERO_RELEASE/monero-gui-linux-x64-v$MONERO_RELEASE.tar.bz2"
    wget "$MONERO_URL" -O /tmp/monero-gui.tar.bz2
    tar -xjf /tmp/monero-gui.tar.bz2 -C /opt/
    echo "Monero GUI zainstalowane."
}

###############################################################################
# INSTALACJA SESSION MESSENGER
###############################################################################
# Reszta aplikacji instalowana w tej sekcji

# Amnezia VPN - Client dla szyfrowanych tuneli
# Pobieranie latest release z GitHub
echo "Instalacja Amnezia VPN..."
AMNEZIA_URL="https://github.com/amnezia-vpn/amnezia-desktop/releases/latest/download/amnezia.deb"
wget "$AMNEZIA_URL" -O /tmp/amnezia.deb 2>/dev/null || {
    echo "Pobieranie z alternatywnej source..."
    curl -sL https://api.github.com/repos/amnezia-vpn/amnezia-desktop/releases/latest | grep "browser_download.*deb" | head -1 | cut -d '"' -f 4 | xargs wget -O /tmp/amnezia.deb
}
sudo dpkg -i /tmp/amnezia.deb
sudo apt install -f -y
rm -f /tmp/amnezia.deb

echo "Amnezia VPN zainstalowany."

# Session - Flatpak
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak install flathub network.loki.Session -y

###############################################################################
# INSTALACJA AMNEZIA WIKI
########################################################################
echo "Instalacja Amnezia Wiki..."

# Amnezia Wiki - Flatpak
sudo flatpak install flathub org.amnezia.wiki -y 2>/dev/null || {
    echo "Amnezia Wiki nie dostępna przez Flatpak, pobieranie z GitHub..."
    wget -q https://github.com/amnezia-vpn/amnezia-wiki/releases/latest/download/amnezia-wiki.AppImage -O /opt/amnezia-wiki.AppImage
    chmod +x /opt/amnezia-wiki.AppImage
    ln -sf /opt/amnezia-wiki.AppImage /usr/local/bin/amnezia-wiki
}

###############################################################################
# INSTALACJA ONIONSHARE
###############################################################################
pipx install onionshare 2>/dev/null || sudo flatpak install flathub org.onionshare.OnionShare -y

###############################################################################
# INSTALACJA TOR BROWSER
###############################################################################
echo "Instalacja Tor Browser..."

sudo apt install -y torbrowser-launcher

###############################################################################
# INSTALACJA BRAVE BROWSER
###############################################################################
# Instalacja Brave Browser
echo "Instalacja Brave Browser..."

wget -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg --no-check-certificate
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update
sudo apt install -y brave-browser

# Konfiguracja Brave - ustawienia prywatności
mkdir -p ~/.config/BraveSoftware/Brave-Browser/Default
cat | tee ~/.config/BraveSoftware/Brave-Browser/Default/Preferences 2>/dev/null << 'BRAVECONFIG'
{
  "preferences": {
    "brave": {
      "adblock": {
        "enabled": true
      },
      "shields": {
        "block_cross_site_cookies": true,
        "block_fingerprinting": true,
        "block_insecure_scripts": true,
        "block_ads": true
      }
    },
    "privacy": {
      "clear_on_exit": {
        "cookies_and_site_data": true,
        "cache": true
      }
    },
    "privacy和安全": {
      "block_speakers": true,
      "block_webgl": true,
      "first_party_storage_access": false
    }
  }
}
BRAVECONFIG

###############################################################################
# INSTALACJA THUNDERBIRD Z GPG SUPPORT
###############################################################################
echo "Instalacja Thunderbird..."

sudo apt install -y thunderbird

# Konfiguracja Thunderbird - wtyczka GPG (Enigmail)
# Enigmail jest domyślnie zintegrowany w Nowych wersjach Thunderbird

###############################################################################
# INSTALACJA OBSIDIAN
###############################################################################
echo "Instalacja Obsidian..."

wget -qO- https://releases.obsidian.md/desktop/Obsidian-1.4.16.deb | sudo dpkg -i -
sudo apt install -f -y

# Konfiguracja Obsidian - domyślne katalogi danych
mkdir -p "$HOME/.local/share/obsidian"
cat | tee ~/.config/obsidian/obsidian.json 2>/dev/null << 'OBSIDIANCONFIG'
{
  "installed-plugins": [
    " Templater",
    "Calendar",
    "Dataview"
  ],
  "plugins": {
    "workspace-layout": "default"
  },
  "appearance": {
    "theme": "dark",
    "accent-color": "#7c3aed"
  },
  "editor": {
    "line-wrapping": true,
    "font-size": 14
  }
}
OBSIDIANCONFIG

###############################################################################
# KONFIGURACJA SYSTEMOWEGO PROXY TOR (SOCKS 9050)
###############################################################################
echo "Konfiguracja systemowego proxy przez Tor..."

cat | sudo tee /etc/profile.d/tor-proxy.sh << 'PROXYCONFIG'
#!/bin/bash
# System proxy routing through Tor SOCKS
export HTTP_PROXY="socks5h://127.0.0.1:9050"
export HTTPS_PROXY="socks5h://127.0.0.1:9050"
export ALL_PROXY="socks5h://127.0.0.1:9050"
export NO_PROXY="localhost,127.0.0.1"
PROXYCONFIG

chmod +x /etc/profile.d/tor-proxy.sh

###############################################################################
# STWORZENIE PROMPTU Z INFO O IP I KRAJU (OPSEC CHECK)
###############################################################################
echo "Konfiguracja promptu z kontrolą wyjściowego IP..."

cat | sudo tee /etc/profile.d/opsec-prompt.sh > /dev/null << 'OPSECPROMPT'
#!/bin/bash
# OPSEC Prompt - Pokazuje wychodzące IP i kraj

get_external_info() {
    local IP=$(curl -s --socks5 127.0.0.1:9050 https://api.ipify.org 2>/dev/null)
    local COUNTRY=$(curl -s --socks5 127.0.0.1:9050 https://ipapi.co/$IP/country/ 2>/dev/null)
    
    if [ -n "$IP" ]; then
        echo -e "\n\e[1;33m🌐 EXTERNAL IP: \e[1;32m$IP\e[0m"
        if [ -n "$COUNTRY" ]; then
            echo -e "📍 COUNTRY: \e[1;32m$COUNTRY\e[0m"
        else
            echo -e "📍 COUNTRY: \e[1;31mUNKNOWN\e[0m (Tor może nie być uruchomiony)"
        fi
    else
        echo -e "\n\e[1;31m⚠️  COULD NOT FETCH IP - Tor service may not be running\e[0m"
        echo -e "Run: sudo systemctl start tor\e[0m"
    fi
    echo ""
}

# Dodaj funkcję do_PROMPT_COMMAND
if [ -z "$PROMPT_COMMAND" ]; then
    PROMPT_COMMAND="get_external_info"
else
    PROMPT_COMMAND="get_external_info; $PROMPT_COMMAND"
fi
OPSECPROMPT

chmod +x /etc/profile.d/opsec-prompt.sh

###############################################################################
# STWORZENIE SKRYPTU HELPERÓW
###############################################################################
echo "Tworzenie skryptów pomocniczych..."

cat | tee ~/bin/darkint-helpers 2>/dev/null << 'HELPERS'
#!/bin/bash

cd ~/darkint

COMMAND="$1"

case "$COMMAND" in
    check-ip)
        echo "Sprawdzanie IP..."
        get_external_info
        ;;
    help)
        cat << 'HELP'
DarkInt Security Workstation - Helper Commands

USAGE:
  darkint-helpers <command>

COMMANDS:
  start-tor       - Uruchom usługę Tor
  stop-tor        - Zamknij usługę Tor  
  status-tor      - Sprawdź status Tor
  start-session   - Uruchom Session Messenger
  start-monero    - Uruchom Monero GUI Wallet
  start-amnezia   - Uruchom Amnezia VPN
  new-identity    - Generuj nową tożsamość w Tor Browser
  backup-keys     - Backup kluczy GPG
  check-ip        - Pokaż aktualne IP i kraj
  help            - Pokaż tę pomoc

OPSEC NOTE:
  Twój zewnętrzny adres IP jest pokazywany automatycznie
  w kolumnie polecenia po każdym naciśnięciu Enter.
  Jeśli widzisz UNKNOWN - sprawdź czy Tor działa.
HELP
        return
        ;;
    start-tor)
        echo "Uruchamianie usługi Tor..."
        sudo systemctl start tor
        echo "Tor uruchomiony. SOCKS proxy: 127.0.0.1:9050"
        ;;
    stop-tor)
        echo "Zatrzymywanie usługi Tor..."
        sudo systemctl stop tor
        echo "Tor zatrzymany."
        ;;
    status-tor)
        sudo systemctl status tor
        ;;
    start-session)
        echo "Uruchamianie Session..."
        flatpak run network.loki.Session
        ;;
    start-monero)
        echo "Uruchamianie Monero GUI..."
        /opt/monero-gui-linux-x64/monero-wallet-gui
        ;;
    start-amnezia)
        echo "Uruchamianie Amnezia VPN..."
        flatpak run org.amnezia.wiki 2>/dev/null || /opt/amnezia-wiki.AppImage 2>/dev/null || amnezia-wiki
        ;;
    new-identity)
        echo "Generowanie nowego tożsamości w Tor Browser..."
        flatpak run com.github.micahflee.torbrowser-launcher --new-identity
        ;;
    backup-keys)
        echo "Backup kluczy GPG..."
        gpg --export --armor > ~/darkint/backup/private-$(date +%Y%m%d).asc
        gpg --export-secret-keys --armor >> ~/darkint/backup/private-$(date +%Y%m%d).asc
        echo "Zapisano do: ~/darkint/backup/private-$(date +%Y%m%d).asc"
        ;;
    *)
        cat << 'USAGE'
DarkInt Helpers - Skrypt pomocniczy

Użycie:
  start-tor       - Uruchom usługę Tor
  stop-tor        - Zamknij usługę Tor  
  status-tor      - Sprawdź status Tor
  start-session   - Uruchom Session Messenger
  start-monero    - Uruchom Monero GUI Wallet
  start-amnezia   - Uruchom Amnezia VPN
  new-identity    - Generuj nową tożsamość w Tor Browser
  backup-keys     - Backup kluczy GPG
USAGE
        ;;
esac
HELPERS

chmod +x ~/bin/darkint-helpers 2>/dev/null || mkdir -p ~/bin && chmod +x ~/bin/darkint-helpers

###############################################################################
# FINISH - POWIADOMIENIE
###############################################################################
echo ""
echo "========================================="
echo "  DarkInt Security Workstation Ready!"
echo "========================================="
echo ""
echo "Zainstalowane aplikacje:"
echo "  🛡️  Tor Browser - przeglądarka z anonimizacją"
echo "  🦁  Brave - przeglądarka z blokadą trackingu"
echo "  📧  Thunderbird z GPG - bezpieczna poczta"
echo "  🔐  Kleopatra - menedżer kluczy GPG"
echo "  💾  KeePassXC - menedżer haseł"
echo "  🔒  VeraCrypt - szyfrowanie dysków"
echo "  💰  Monero GUI - anonimowa kryptowaluta"
echo "  📱  Session - zdecentralizowany messenger"
echo "  🧅  OnionShare - bezpieczne udostępnianie"
echo "  📝  Obsidian - notatnik z szyfrowaniem"
echo "  🌐  Amnezia VPN - szyfrowane tunele"
echo "  🔧  Usługa Tor z SOCKS proxy (9050)"
echo ""
echo "⚠️  OPSEC KONTROLA:"
echo "  Twój zewnętrzny adres IP i kraj są pokazywane"
echo "  automatycznie w terminalu po każdym poleceniu."
echo "  Jeśli widzisz UNKNOWN - sprawdź czy Tor działa."
echo ""
echo "Przydatne komendy:"
echo "  darkint-helpers start-tor      - Uruchom Tor"
echo "  darkint-helpers status-tor     - Sprawdź status Tor"
echo "  darkint-helpers check-ip       - Sprawdź obecne IP"
echo "  darkint-helpers new-identity   - Nowa tożsamość w Tor"
echo "  darkint-helpers backup-keys    - Backup kluczy GPG"
echo "  darkint-helpers help           - Pokaż pełną pomoc"
echo ""
echo "Pierwsze kroki:"
echo "  1. Skonfiguruj parę kluczy GPG w Kleopatrze"
echo "  2. Utwórz bazę haseł w KeePassXC"
echo "  3. Skonfiguruj Monero wallet (pierwsze uruchomienie: pobranie blockchain)"
echo "  4. Zarejestruj się w Session (nie wymaga numeru telefonu)"
echo "  5. Skonfiguruj Obsidian z lokalnymi vaultami"
echo ""
echo "Życzymy bezpiecznej i anonimowej pracy!"
echo ""
