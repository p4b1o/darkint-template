# DarkInt Security Workstation

<div align="center">

**Polska stacja robocza dla analityków bezpieczeństwa i operacji tajnych**

*Automatyczna instalacja i konfiguracja środowiska worklowego z naciskiem na prywatność, kryptografię i anonimizację*

</div>

---

## 🎯 O projekcie

Tworząc environment dla profesjonalistów zajmujących się security research, operacjami wywiadu cyfrowego i testami penetracyjnymi, potrzebne jest narzędziowo zorientowane podejście. Ten projekt automatyzuje konfigurację pełnego stanowiska pracy w **15-20 minut**.

Skrypt jest przeznaczony dla analityków wymagających:
- 🛡️ **Pełnej kontroli nad tożsamością cyfrową**
- 🔐 **Narzędzi kryptograficznych** (GPG, szyfrowanie dysków)
- 💻 **Anonimowości sieciowej** (Tor, SOCKS proxy)
- 💰 **Anonimowości transakcyjnej** (Monero)
- 🔒 **Bezpiecznej komunikacji** (Session, Thunderbird z GPG)
- 📝 **Organizacji pracy** (Obsidian, lokalne bazy danych)

---

## ⚡ Instalacja

### Wymagania
- **Debian 12 lub 13** z środowiskiem XFCE (standardowa instalacja)
- **Uprawnienia sudo** (wymagane do konfiguracji systemu)
- **4GB RAM** (zalecane 8GB)
- **20GB** wolnego miejsca
- **Połączenie internetowe**

### Jedna komenda
```bash
curl -O https://raw.githubusercontent.com/p4b1o/darkint-template/main/setup.sh && chmod +x setup.sh && ./setup.sh
```

**To wszystko!** Za 15-20 minut masz gotowe środowisko pracy.

---

## 🛠️ Co instaluje ten skrypt

### Narzędzia bezpieczeństwa i prywatności
- **Kleopatra** - menedżer certyfikatów GPG/OpenPGP
- **KeePassXC** - lokalny menedżer haseł z szyfrowaniem AES-256
- **VeraCrypt** - szyfrowanie dysków i wirtualnych kontenerów
- **Monero GUI Wallet** - anonimowa kryptowaluta z naciskiem na prywatność
- **Session** - zdecentralizowana komunikacja bez numeru telefonu
- **Amnezia VPN** - szyfrowane tunele VPN z własnymi serwerami
- **OnionShare** - bezpieczne udostępnianie plików przez Tor

### Przeglądarki i klient pocztowy
- **Tor Browser** - przeglądarka z naciskiem na prywatność i anonimizację
- **Brave** - przeglądarka z wbudowanym blockerem trackingu
- **Thunderbird** - klient pocztowy z pełnym wsparciem GPG

### Narzędzia dodatkowe
- **Obsidian** - zaawansowany notatnik z lokalnym przechowywaniem danych
- **Tor (usługa)** - lokalny daemon Tor z konfiguracją SOCKS proxy

---

## 🔒 Bezpieczeństwo i prywatność

Skrypt konfiguruje środowisko zgodnie z najlepszymi praktykami:

✅ **Tor usługa uruchamiana automáticamente z SOCKS proxy**  
✅ **Ustawienia prywatności w Brave**  
✅ **Konfiguracja kontenerów dla Tor Browser**  
✅ **Lokalne przechowywanie danych w Obsidian**  
✅ **KeePassXC z automatycznym blokowaniem**  
✅ **Session bez powiązań z numerem telefonu**  
✅ **Monero z domyślną integracją z Tor**  

---

## 📊 Porównanie z OSINT-template

| Cecha | DarkInt Security | OSINT Template |
|------|------------------|---------------|
| **Środowisko** | 🔧 XFCE | 🎨 GNOME |
| **Focus** | 🛡️ Bezpieczeństwo | 🔍 OSINT research |
| **Kryptografia** | ✅ GPG, szyfrowanie | ❌ Brak |
| **Anonimowość finansowa** | ✅ Monero | ❌ Brak |
| **Komunikacja** | ✅ Session, Thunderbird GPG | ✅ Podstawowa |
| **VPN** | ✅ Amnezia | ❌ Brak |
| **Narzędzia research** | ❌ Limited | ✅ 15+ narzędzi |
| **Czas instalacji** | ⚡ 15-20 min | ⚡ 15 min |

---

## 💡 Typowe przypadki użycia

### Security Research
Analiza zagrożeń, research podatności, threat intelligence w środowisku odizolowanym.

### Operational Security (OpSec)
Praca z wrażliwymi danymi z zachowaniem pełnej kontroli nad tożsamością cyfrową.

### Secure Communication
Bezpieczna korespondencja z użyciem GPG i zdecentralizowanych platform.

### Privacy-Focused Development
Programowanie z naciskiem na ochronę prywatności i bezpieczeństwo kodu.

---

## 🔄 Podstawowe workflow po instalacji

### 1. Uruchomienie Tor usługi
```bash
sudo systemctl start tor
sudo systemctl enable tor
```

### 2. Sprawdzenie IP i kraju (automatyczne)
Po każdym poleceniu w terminalu zobaczysz swój zewnętrzny adres IP i kraj.
Jeśli widzisz "UNKNOWN" - Tor może nie być uruchomiony.

Ręczna komenda:
```bash
darkint-helpers check-ip
```

### 3. Kontrola opsec
Terminal wyświetla automatycznie zewnętrzny IP i kraj po każdym poleceniu.  
To pozwala na ciągłą weryfikację czy komunikacja idzie przez Tor.

### 4. Pierwsze uruchomienie KeePassXC
Skrypt automatycznie konfiguruje systemowe ustawienia proxy przez Tor SOCKS (127.0.0.1:9050).

### 3. Pierwsze uruchomienie KeePassXC
Utwórz bazę haseł z głównym hasłem i/z kluczem pliku.

### 4. Setup GPG w Kleopatrze
Wytwórz parę kluczy (publiczny/prywatny) do szyfrowania i podpisów.

### 5. Session - rejestracja
Uruchom Session - nie wymaga numeru telefonu, otrzymasz Session ID.

### 6. Pomoc
```bash
darkint-helpers help
```

### 7. Amnezia VPN - konfiguracja
Uruchom Amnezia VPN i skonfiguruj własny serwer lub użyj publicznych.

---

## 📁 Struktura skryptu

Skrypt podzielony jest na sekcje:

1. **Aktualizacja i czyszczenie** - aktualizacja systemu
2. **Podstawowe narzędzia** - wget, curl, git, python
3. **XFCE i ustawienia systemowe** - środowisko graficzne
4. **Tor + SOCKS proxy** - usługa Tor z konfiguracją
5. **Bezpieczeństwo** - KeePassXC, VeraCrypt, Monero
6. **Kryptografia** - Kleopatra, Thunderbird + GPG
7. **Komunikacja** - Session, OnionShare
8. **Przeglądarki** - Tor Browser, Brave
9. **Organizacja pracy** - Obsidian
10. **Finalizacja** - ustawienia panelu, reboot

---

## ⚠️ Ważne uwagi

### Bezpieczeństwo
- Po instalacji zmierz swoje środowisko pracy
- Regularnie aktualizuj system i aplikacje
- Używaj różnych tożsamości dla różnych celów
- Nie mieszkaj tożsamości w ramach tego środowiska

### Monero
- Uruchamiając Monero GUI po raz pierwszy, pobierzesz cały blockchain (~150GB)
- Dla lepszej prywatności użyjRemote node zamiast lokalnego node

### Backup
- Twórz regularne backupy swojej bazy KeePassXC
- Eksportuj klucze GPG i przechowuj w bezpiecznym miejscu
- Backup kluczowy dla Monero (seed)

---

## 📄 Licencja

Projekt udostępniam na licencji MIT - możesz go swobodnie używać, modyfikować i dystrybuować.

---

<div align="center">

**Stworzony przez Pawła Hordyńskiego dla społeczności security i privacy**

*Twoje bezpieczeństwo cyfrowe zaczyna się tutaj.*

</div>
