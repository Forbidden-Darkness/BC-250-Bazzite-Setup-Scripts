#!/usr/bin/env bash
clear

# ==============================================================================
# PREMIUM TERMINAL COLOR PALETTE & VISUAL PROPERTIES
# ==============================================================================
RED='\033[0;31m'
B_RED='\033[1;31m'
GREEN='\033[0;32m'
B_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
B_BLUE='\033[1;34m'
B_VIOLET='\033[1;35m'
CYAN='\033[0;36m'
BIBlack='\033[1;90m'
BIRed='\033[1;91m'
BIGreen='\033[1;92m'
BIYellow='\033[1;93m'
BIBlue='\033[1;94m'
BIPurple='\033[1;95m'
BICyan='\033[1;96m'
BIWhite='\033[1;97m'
NC='\033[0m'
RESET='\033[0m'

DIM='\033[38;2;110;110;110m'
BOLD='\033[1m'

# Verify root/sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run with sudo or as root."
    echo -e "Please run: sudo bash $0${NC}"
    exit 1
fi

# Establish Execution Context
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SCRIPT_PATH=$(realpath "$0")

print_info() { echo -e "  ${CYAN}→${RESET}  $1"; }
print_success() { echo -e "\n  ${BOLD}${GREEN}✔  $1${RESET}\n"; }
print_error() { echo -e "\n  ${BOLD}${RED}✘  $1${RESET}\n"; }

# ==============================================================================
# INTERACTIVE DESKTOP SHORTCUT HOOK
# ==============================================================================
ask_desktop_shortcut() {
    local desktop_dir
    desktop_dir="$(sudo -u "$REAL_USER" xdg-user-dir DESKTOP 2>/dev/null || echo "")"
    [[ -n "$desktop_dir" ]] || desktop_dir="$REAL_HOME/Desktop"
    [[ -d "$desktop_dir" ]] || mkdir -p "$desktop_dir" 2>/dev/null || return 0

    local shortcut="$desktop_dir/Start Wake on LAN Manager.desktop"
    [[ -f "$shortcut" ]] && return 0

    echo -e "  ${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║                  DESKTOP SHORTCUT CONFIGURATION                   ║${NC}"
    echo -e "  ${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BIYellow}Would you like to add an application shortcut to your desktop?${NC}"
    echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
    echo -e "    ${CYAN}1)${NC} Yes, create desktop shortcut     ${BIBlack}(Generates native launcher file)${NC}"
    echo ""
    echo -e "    ${CYAN}2)${NC} No, skip shortcut creation"
    echo ""
    echo -e "    ${RED}[Enter]${NC} Skip and continue to dashboard parameters"
    echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
    echo ""

    read -rp "$(echo -e "  ${CYAN}Select an option [1-2]: ${NC}")" shortcut_choice

    case $shortcut_choice in
        1)
            sudo -u "$REAL_USER" tee "$shortcut" > /dev/null <<SHORTCUT_EOF
[Desktop Entry]
Type=Application
Name=Wake on LAN Manager
Comment=Manage Remote Wake-on-LAN Parameters
Exec=konsole -e sudo bash "$SCRIPT_PATH"
Icon=utilities-terminal
Terminal=false
Categories=System;
SHORTCUT_EOF
            chmod +x "$shortcut"
            chown "$REAL_USER":"$REAL_USER" "$shortcut" 2>/dev/null || true
            sudo -u "$REAL_USER" gio set "$shortcut" metadata::trusted true >/dev/null 2>&1 || true
            print_success "Wake on LAN Manager shortcut created successfully!"
            sleep 1.5
            ;;
        2|*)
            print_info "Skipping desktop shortcut generation."
            sleep 1
            ;;
    esac
}

ask_desktop_shortcut
clear

# ==============================================================================
# MAIN DEPLOYMENT ACTIONS INTERFACE
# ==============================================================================
echo -e "  ${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "  ${CYAN}║                  WAKE-on-LAN CONFIGURATION MANAGER                ║${NC}"
echo -e "  ${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}${YELLOW}Deployment Actions & Settings${NC}"
echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
echo -e "    ${CYAN}[1]${NC} Enable WoL (magic packet)       ${BIBlack}(Recommended for remote power-on)${NC}"
echo ""
echo -e "    ${CYAN}[2]${NC} Disable WoL (ignore)            ${BIBlack}(Standard power-saving state)${NC}"
echo ""
echo -e "    ${RED}[Enter]${NC} Abort Tweak and Return to Primary Menu"
echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
echo ""

read -rp "$(echo -e "  ${CYAN}Select an option [1-2]: ${NC}")" ACTION_CHOICE

# 🧬 FIXED LOGIC STEP: Safely intercepts unassigned inputs to route cleanly back up to start.sh
if [ "$ACTION_CHOICE" = "1" ]; then
    WOL_SETTING="magic"
    ACTION_TEXT="Enabling"
elif [ "$ACTION_CHOICE" = "2" ]; then
    WOL_SETTING="ignore"
    ACTION_TEXT="Disabling"
elif [ -z "$ACTION_CHOICE" ]; then
    echo -e "  ${YELLOW}[-] Operation canceled. Returning safely to master toolkit...${NC}"
    sleep 1.2
    exit 0
else
    print_error "Invalid option selected. Aborting."
    exit 1
fi

# ==============================================================================
# DEVICE CARD FILTER & DISCOVERY MATRIX
# ==============================================================================
CONNECTIONS=()
while read -r conn_name; do
    [ -z "$conn_name" ] && continue
    raw_type=$(nmcli -g connection.type connection show "$conn_name" 2>/dev/null)
    if [[ "$raw_type" == *"ethernet"* || "$raw_type" == *"wireless"* ]]; then
        CONNECTIONS+=("$conn_name")
    fi
done < <(nmcli -g NAME connection show)

if [ ${#CONNECTIONS[@]} -eq 0 ]; then
    print_error "No active NetworkManager Ethernet or Wireless profiles discovered."
    echo "  ------------------------------------------------"
    nmcli connection show
    exit 1
fi

echo -e "\n  ${BOLD}${YELLOW}Discovered Host Network Interfaces:${RESET}"
echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
echo -e "    ${CYAN}[0]${NC} CONFIGURE ALL DISCOVERED INTERFACES"
for i in "${!CONNECTIONS[@]}"; do
    printf "    ${CYAN}[%d]${NC} %s\n" "$((i+1))" "${CONNECTIONS[$i]}"
done
echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
echo ""
echo -e "  ${DIM}Enter profile indices separated by spaces (e.g., '1 3') or select '0'.${RESET}"
read -rp "$(echo -e "  ${CYAN}Selection Array: ${NC}")" -a USER_SELECTIONS

TARGET_CONNECTIONS=()
if [[ " ${USER_SELECTIONS[*]} " =~ " 0 " ]]; then
    TARGET_CONNECTIONS=("${CONNECTIONS[@]}")
else
    for sel in "${USER_SELECTIONS[@]}"; do
        if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -le "${#CONNECTIONS[@]}" ] && [ "$sel" -gt 0 ]; then
            TARGET_CONNECTIONS+=("${CONNECTIONS[$((sel-1))]}")
        else
            echo -e "  ${RED}[⚠] Warning: Ignoring out-of-bounds index link selection '$sel'.${NC}"
        fi
    done
fi

if [ ${#TARGET_CONNECTIONS[@]} -eq 0 ]; then
    print_error "No valid interface targets assigned. Exiting."
    exit 1
fi

# ==============================================================================
# PARAMETER MODIFICATION & COMMIT PIPELINE
# ==============================================================================
echo -e "\n  ${GREEN}[+] Synchronizing bus properties across selected adapters...${NC}"
echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"

for CONN in "${TARGET_CONNECTIONS[@]}"; do
    [ -z "$CONN" ] && continue
    echo -e "  ⚡ Processing: ${BIWhite}'$CONN'${NC}"

    CONN_TYPE=$(nmcli -g connection.type connection show "$CONN" 2>/dev/null)
    if [[ "$CONN_TYPE" == *"ethernet"* ]]; then
        PROP_PREFIX="802-3-ethernet"
    elif [[ "$CONN_TYPE" == *"wireless"* ]]; then
        PROP_PREFIX="802-11-wireless"
    else
        echo -e "  ${RED}❌ Skipping unsupported interface archetype: $CONN_TYPE${NC}"
        echo "  ------------------------------------------------"
        continue
    fi

    echo -e "     ↳ ${ACTION_TEXT} hardware register configurations..."
    nmcli c modify "$CONN" "${PROP_PREFIX}.wake-on-lan" "$WOL_SETTING"

    echo -e "     ↳ Live Status Verification:"
    nmcli c show "$CONN" | grep -i "wake-on-lan" | sed 's/^/       /'
    echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
done

# ==============================================================================
# POST-CONFIGURATION ENVIRONMENT STATE TRANSITIONS
# ==============================================================================
print_success "Network interface tuning complete!"
echo -e "  ${BOLD}${YELLOW}What would you like to do next?${NC}"
echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
echo -e "    ${CYAN}[1]${NC} Restart NetworkManager service  ${DIM}(Apply custom layers immediately)${RESET}"
echo ""
echo -e "    ${CYAN}[2]${RESET} Reboot the entire system"
echo ""
echo -e "    ${RED}[3] Do nothing (Clean exit)${NC}"
echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
echo ""
read -rp "$(echo -e "  ${CYAN}Select option index [1-3]: ${NC}")" POST_CHOICE

case "$POST_CHOICE" in
    1)
        echo -e "\n  ${GREEN}[+] Restarting NetworkManager daemon sub-systems...${NC}"
        systemctl restart NetworkManager
        print_success "NetworkManager registers successfully flushed and reloaded."
        sleep 1.5
        ;;
    2)
        echo -e "\n  ${GREEN}[+] Flushing disk state memory maps. Rebooting device...${NC}"
        sleep 1.5
        reboot
        ;;
    *)
        echo -e "\n  ${YELLOW}[-] Exiting cleanly. Changes will persist upon next network/system reload.${NC}"
        sleep 1.5
        ;;
esac
