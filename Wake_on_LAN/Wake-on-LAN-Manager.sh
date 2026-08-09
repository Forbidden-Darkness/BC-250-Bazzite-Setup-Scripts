#!/usr/bin/env bash
clear

# Color definitions
RED='\033[0;31m'
B_RED='\033[1;31m'   # Bold Red for high-visibility Red Pill elements
GREEN='\033[0;32m'
B_GREEN='\033[1;32m' # Bold Green for verified/active status
YELLOW='\033[1;33m'
B_BLUE='\033[1;34m'  # Bold Blue for high-visibility Blue Pill elements
B_VIOLET='\033[1;35m' # Bold Violet for ACPI Fix elements
CYAN='\033[0;36m'
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White
NC='\033[0m' # No Color (Reset)

# 1. Verify root/sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run with sudo or as root."
    echo -e "Please run: sudo bash $0${NC}"
    exit 1
fi

# =====================================================================
# FIX: Environment Variable Definitions & Custom Print Functions
# =====================================================================
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SCRIPT_PATH=$(realpath "$0")

print_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}
# =====================================================================

# NEW: Interactive Desktop Shortcut Handler
ask_desktop_shortcut() {
    local desktop_dir
    desktop_dir="$(sudo -u "$REAL_USER" xdg-user-dir DESKTOP 2>/dev/null || echo "")"
    [[ -n "$desktop_dir" ]] || desktop_dir="$REAL_HOME/Desktop"
    [[ -d "$desktop_dir" ]] || mkdir -p "$desktop_dir" 2>/dev/null || return 0

    local shortcut="$desktop_dir/Wake on LAN Manager.desktop"

    # If the shortcut already exists, don't keep bothering the user
    if [[ -f "$shortcut" ]]; then
        return 0
    fi

    echo -e "${BIYellow}==================================================${NC}"
    echo -e "${BIYellow}         DESKTOP SHORTCUT CONFIGURATION           ${NC}"
    echo -e "${BIYellow}==================================================${NC}"
    echo -e "Would you like to add a shortcut to your desktop?"
    echo ""
    echo -e " 1) Yes, create desktop shortcut"
    echo ""
    echo -e " 2) No, skip shortcut creation"
    echo ""
    echo -e "${BIYellow}==================================================${NC}"
    read -rp "Select an option [1-2]: " shortcut_choice

    case $shortcut_choice in
        1)
            # FIX: Execute file generation explicitly as the real local user context to bypass sudo restrictions
            sudo -u "$REAL_USER" tee "$shortcut" > /dev/null <<SHORTCUT_EOF
[Desktop Entry]
Type=Application
Name=Wake on LAN Manager
Comment=Wake on LAN Manager
Exec=konsole -e sudo bash "$SCRIPT_PATH"
Icon=utilities-terminal
Terminal=false
Categories=System;
SHORTCUT_EOF

            chmod +x "$shortcut"
            chown "$REAL_USER":"$REAL_USER" "$shortcut" 2>/dev/null || true
            sudo -u "$REAL_USER" gio set "$shortcut" metadata::trusted true >/dev/null 2>&1 || true
            print_info "Wake on LAN Manager shortcut created successfully!"
            sleep 2
            ;;
        2)
            print_info "Skipping desktop shortcut generation."
            sleep 1.5
            ;;
        *)
            print_info "Invalid choice. Skipping shortcut setup for now."
            sleep 1.5
            ;;
    esac
}

# Run the optional shortcut menu before opening the primary toolkit
ask_desktop_shortcut

clear
# 2. Ask user for Action (Enable or Disable)
echo -e "${YELLOW}=============================================${NC}"
echo " Wake-on-LAN Configuration Manager"
echo -e "${YELLOW}=============================================${NC}"
echo ""
echo -e "${YELLOW}What action would you like to perform?${NC}"
echo ""
echo -e "${B_BLUE}1) Enable WoL (magic packet)${NC}"
echo ""
echo -e "${RED}2) Disable WoL (ignore)${NC}"
echo ""
echo -e "${YELLOW}0) Exit Wake-on-LAN${NC}"
echo ""
read -rp "Select an option (1 or 2): " ACTION_CHOICE

if [ "$ACTION_CHOICE" = "1" ]; then
    WOL_SETTING="magic"
    ACTION_TEXT="Enabling"
elif [ "$ACTION_CHOICE" = "2" ]; then
    WOL_SETTING="ignore"
    ACTION_TEXT="Disabling"
elif [ "$choice" == "0" ] || [ -z "$choice" ]; then
        echo "Exiting."
        exit 0
else
    echo "Invalid option. Exiting."
    exit 1
fi

# 3. Fetch all Ethernet and Wireless connection profiles safely
# Modified to pull ALL profiles first, then filter dynamically by underlying connection type
CONNECTIONS=()
while read -r conn_name; do
    [ -z "$conn_name" ] && continue
    # Get the raw connection type property
    raw_type=$(nmcli -g connection.type connection show "$conn_name" 2>/dev/null)
    if [[ "$raw_type" == *"ethernet"* || "$raw_type" == *"wireless"* ]]; then
        CONNECTIONS+=("$conn_name")
    fi
done < <(nmcli -g NAME connection show)

if [ ${#CONNECTIONS[@]} -eq 0 ]; then
    echo "Error: No NetworkManager Ethernet or Wireless profiles found."
    echo "------------------------------------------------"
    echo "System Diagnostic Info:"
    nmcli connection show
    exit 1
fi

# 4. Interactive Interface Selection Menu
echo ""
echo "Found the following network profiles:"
echo "0) ALL CONNECTIONS"
for i in "${!CONNECTIONS[@]}"; do
    echo "$((i+1))) ${CONNECTIONS[$i]}"
done

echo ""
echo "Which profiles do you want to configure?"
echo "Enter numbers separated by spaces (e.g., '1 3') or '0' for all."
read -rp "Selection: " -a USER_SELECTIONS

# Process selections into a target list
TARGET_CONNECTIONS=()
if [[ " ${USER_SELECTIONS[*]} " =~ " 0 " ]]; then
    TARGET_CONNECTIONS=("${CONNECTIONS[@]}")
else
    for sel in "${USER_SELECTIONS[@]}"; do
        # Validate that the input is a valid number within range
        if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -le "${#CONNECTIONS[@]}" ] && [ "$sel" -gt 0 ]; then
            TARGET_CONNECTIONS+=("${CONNECTIONS[$((sel-1))]}")
        else
            echo "Warning: Ignoring invalid selection '$sel'."
        fi
    done
fi

if [ ${#TARGET_CONNECTIONS[@]} -eq 0 ]; then
    echo "Error: No valid connections selected. Exiting."
    exit 1
fi

# 5. Apply Changes to Selected Connections
echo ""
echo "Applying changes..."
echo "------------------------------------------------"

for CONN in "${TARGET_CONNECTIONS[@]}"; do
    [ -z "$CONN" ] && continue

    echo "Processing connection: '$CONN'"

    # Dynamically determine connection type
    CONN_TYPE=$(nmcli -g connection.type connection show "$CONN" 2>/dev/null)

    if [[ "$CONN_TYPE" == *"ethernet"* ]]; then
        PROP_PREFIX="802-3-ethernet"
    elif [[ "$CONN_TYPE" == *"wireless"* ]]; then
        PROP_PREFIX="802-11-wireless"
    else
        echo "  Skipping unsupported type: $CONN_TYPE"
        echo "------------------------------------------------"
        continue
    fi

    # Update WoL Setting
    echo "  $ACTION_TEXT WoL..."
    nmcli c modify "$CONN" "${PROP_PREFIX}.wake-on-lan" "$WOL_SETTING"

    # Verify Output
    echo "  Current status:"
    nmcli c show "$CONN" | grep -i "wake-on-lan" | sed 's/^/    /'
    echo "------------------------------------------------"
done

# 6. Post-Configuration Actions
echo "Configuration complete."
echo "What would you like to do next?"
echo "1) Restart NetworkManager service (Apply settings immediately)"
echo "2) Reboot the entire system"
echo "3) Do nothing (Exit script)"
read -rp "Select an option (1, 2, or 3): " POST_CHOICE

case "$POST_CHOICE" in
    1)
        echo "Restarting NetworkManager service..."
        systemctl restart NetworkManager
        echo "NetworkManager successfully restarted."
        ;;
    2)
        echo "Rebooting system now..."
        reboot
        ;;
    *)
        echo "Exiting without reloading. Remember changes may require a reboot or service restart to take effect."
        ;;
esac
