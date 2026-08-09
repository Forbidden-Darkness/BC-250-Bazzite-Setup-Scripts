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

# Verify root/sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run with sudo or as root."
    echo -e "Please run: sudo bash $0${NC}"
    exit 1
fi
# --- FULL SCREEN FORCE WRAPPER ---
# If not already maximized/fullscreen and running interactively, try to force full screen
if [ -z "$TERMINAL_FULLSCREEN_FORCED" ] && [ -t 0 ]; then
    export TERMINAL_FULLSCREEN_FORCED=1

    # Method 1: Check for wmctrl (Common on Linux desktops) and maximize
    if command -v wmctrl &> /dev/null; then
        wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
    fi

    # Method 2: Send ANSI escape sequence to maximize terminal window size (supported by Konsole/GNOME)
    echo -ne "\033[9;1t"

    # Method 3: Alternative ANSI sequence to switch to full-screen mode
    echo -ne "\033[11t"

    clear
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

    local shortcut="$desktop_dir/Start Bazzite Boken Toolbox.desktop"

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
            cat > "$shortcut" <<SHORTCUT_EOF
[Desktop Entry]
Type=Application
Name=Bazzite Boken Toolbox
Comment=Manage Memory - Overclock - Wake on Lan
Exec=konsole -e sudo bash "$SCRIPT_PATH"
Icon=utilities-terminal
Terminal=false
Categories=System;
SHORTCUT_EOF

            chmod +x "$shortcut"
            chown "$REAL_USER":"$REAL_USER" "$shortcut" 2>/dev/null || true
            sudo -u "$REAL_USER" gio set "$shortcut" metadata::trusted true >/dev/null 2>&1 || true
            print_info "Bazzite Boken Toolbox shortcut created successfully!"
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

# Run the shortcut configuration function
ensure_desktop_shortcut

# ---------------------------------
# Function to pause and offer a Cancel Reboot option
prompt_reboot() {
    echo ""
    echo -e "${YELLOW}==================================================${NC}"
    echo -e "${YELLOW} Task complete! The system needs to reboot now.   ${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo " 1) Reboot Now (Recommended)"
    # Changed the Text and Flow: Modified choice 2 inside prompt_reboot to explicitly state it returns to the main menu.
    echo " 2) Cancel Reboot & Return to Main Menu"
    echo -e "${YELLOW}==================================================${NC}"
    read -rp "Select an option [1-2]: " reboot_choice

    case $reboot_choice in
        1)
            echo "Rebooting system now..."
            sudo systemctl reboot
            ;;
        2)
            echo -e "${YELLOW}Reboot cancelled. Returning to main menu. Remember to reboot manually later for changes to take effect.${NC}"
            # Added sleep delays: Included short visual delays (sleep 2) so the user has time to read the status updates before the menu redraws and clears the screen.
            sleep 2
            # Used return instead of exit: Replaced potential script termination points inside the sub-function with return 0, sending the code execution back to the primary menu loop.
            return 0
            ;;
        *)
            echo -e "${RED}Invalid option. Defaulting to safe cancel. Returning to main menu.${NC}"
            sleep 2
            return 1
            ;;
    esac
}

# Function to handle Blue Pill installation
install_blue_pill() {
    echo -e "${B_BLUE}=== Executing Blue Pill (16GB Setup) ===${NC}"
    mkdir -p ~/Blue_Pill_16GB
    cd ~/Blue_Pill_16GB || return 1
    rm -f Setup-16GB.sh
    wget https://raw.githubusercontent.com/NexGen-3D-Printing/SteamMachine/main/Setup-16GB.sh
    chmod +x Setup-16GB.sh
    sudo ./Setup-16GB.sh
    prompt_reboot
}

# Function to handle Red Pill installation
install_red_pill() {
    echo -e "${B_RED}=== Executing Red Pill (32GB Setup) ===${NC}"
    mkdir -p ~/Red_Pill_32GB
    cd ~/Red_Pill_32GB || return 1
    rm -f Setup-32GB.sh
    wget https://raw.githubusercontent.com/NexGen-3D-Printing/SteamMachine/main/Setup-32GB.sh
    chmod +x Setup-32GB.sh
    sudo ./Setup-32GB.sh
    prompt_reboot
}

## Function to Launch Overclock
install_overclock() {
    echo -e "${B_RED}=== Launching Overclock Menu ===${NC}"

    # 1. Setup the directory using the absolute path to your real user home
    local oc_dir="$REAL_HOME/Bazzite_Toolbox/Overclock"
    mkdir -p "$oc_dir"
    cd "$oc_dir" || return 1
    chown -R "$REAL_USER":"$REAL_USER" "$oc_dir"

    # 2. Download the clean RAW file using your true user context
    rm -f Overclock-Live-Manager.sh
    sudo -u "$REAL_USER" wget https://github.com/Forbidden-Darkness/Bazzite_Toolbox/raw/refs/heads/main/Overclock/Overclock-Live-Manager.sh

    # 3. Crash proof step: Verify the file exists and is not empty
    if [ ! -s "Overclock-Live-Manager.sh" ]; then
        echo -e "${RED}ERROR: Script failed to download or is blank! Check internet.${NC}"
        sleep 4
        return 1
    fi

    # 4. Make it executable
    chmod +x Overclock-Live-Manager.sh

    # 5. EXECUTION FIX FOR SHORTCUTS:
    # Instead of spinning a nested sudo layer, clear the current environment
    # variable space and source the script directly into the open terminal console frame.
    echo "Transitioning terminal to Overclock Live Manager..."
    sleep 1

    ENVIRONMENT=bazzite Overrides=true bash ./Overclock-Live-Manager.sh

    # 6. Fallback step to keep the window open if the inner script closes
    echo -e "${YELLOW}Overclock Manager closed. Returning to main menu...${NC}"
    sleep 2
}

# Function to Launch Wake on LAN
install_wake_on_lan() {
    echo -e "${B_RED}=== Launching Wake on LAN Menu ===${NC}"

    # 1. Setup the directory using the absolute path to your real user home
    local wol_dir="$REAL_HOME/Bazzite_Toolbox/Wake_on_LAN"
    mkdir -p "$wol_dir"
    cd "$wol_dir" || return 1
    chown -R "$REAL_USER":"$REAL_USER" "$wol_dir"

    # 2. Download the clean RAW file using your true user context
    rm -f Wake-on-LAN-Manager.sh
    sudo -u "$REAL_USER" wget https://github.com/Forbidden-Darkness/Bazzite_Toolbox/raw/refs/heads/main/Wake_on_LAN/Wake-on-LAN-Manager.sh

    # 3. Crash proof step: Verify the file exists and is not empty
    if [ ! -s "Wake-on-LAN-Manager.sh" ]; then
        echo -e "${RED}ERROR: Script failed to download or is blank! Check internet.${NC}"
        sleep 4
        return 1
    fi

    # 4. Make it executable
    chmod +x Wake-on-LAN-Manager.sh

    # 5. EXECUTION FIX FOR SHORTCUTS:
    # Instead of spinning a nested sudo layer, clear the current environment
    # variable space and source the script directly into the open terminal console frame.
    echo "Transitioning terminal to Wake on LAN Manager..."
    sleep 1

    ENVIRONMENT=bazzite Overrides=true bash ./Wake-on-LAN-Manager.sh

    # 6. Fallback step to keep the window open if the inner script closes
    echo -e "${YELLOW}Wake on LAN Manager closed. Returning to main menu...${NC}"
    sleep 2
}

# Function to handle ACPI Override Fix
apply_acpi_fix() {
    echo -e "${B_VIOLET}=== Executing BC-250 ACPI Fix ===${NC}"

    # 1. Clone repository to a temporary workspace
    cd /tmp || return 1
    rm -rf acpi_tables/kernel/firmware/acpi
    #rm -rf bc250-acpi-fix
    git clone https://github.com/mendesrr/bc250-acpi-fix-updated-8c.git
    cd bc250-acpi-fix-updated-8c # New Line added
    #git clone https://github.com/bc250-collective/bc250-acpi-fix.git

    # Check if cloning succeeded before continuing
    if [ ! -d "/tmp/bc250-acpi-fix-updated-8c" ]; then
    #if [ ! -d "/tmp/bc250-acpi-fix" ]; then
        echo -e "${RED}ERROR: Failed to clone the ACPI fix repository. Check your internet connection.${NC}"
        sleep 2
        return 1
    fi

    # 2. Build the early initrd structure inside /tmp
    rm -rf /tmp/acpi_tables/kernel/firmware/acpi
    #rm -rf /tmp/acpi_tables
    mkdir -p /tmp/acpi_tables/kernel/firmware/acpi
    cp *.aml /tmp/acpi_tables/kernel/firmware/acpi/.
    #cp /tmp/bc250-acpi-fix/*.aml /tmp/acpi_tables/kernel/firmware/acpi/

    # 3. Create the cpio archive
    cd /tmp/acpi_tables || return 1
    find kernel | cpio -H newc --create > SSDT_ACPI.cpio

    # 4. Copy to boot, update grub default settings, and regenerate grub
    sudo cp SSDT_ACPI.cpio /boot/.
    echo 'GRUB_EARLY_INITRD_LINUX_CUSTOM="../../SSDT_ACPI.cpio"' | sudo tee -a /etc/default/grub
    ujust regenerate-grub

    # 5. Layer the kernel-tools package for Bazzite's atomic filesystem
    echo -e "${B_VIOLET}=== Installing kernel-tools (cpupower) ===${NC}"
    rpm-ostree install kernel-tools

    prompt_reboot
}

# Wrapped in a Menu Loop: Embedded the menu options inside a while true loop function (show_menu) so that it repeats indefinitely until explicitly exited.
show_menu() {
    while true; do
        # Clear the screen for a clean menu presentation
        clear
        echo -e "${CYAN}==========================================${NC}"
        echo -e "${CYAN}    SteamMachine RAM Setup Selector       ${NC}"
        echo -e "${CYAN}==========================================${NC}"
        echo "Please choose an option:"
        echo -e "1) ${B_BLUE}Blue Pill${NC} (16GB Script)"
        echo -e "2) ${B_RED}Red Pill${NC}  (32GB Script)"
        echo ""
        echo -e "3) Apply ${B_VIOLET}Apply ACPI Fix${NC}"
        echo -e "4) ${B_GREEN}Launch BC250 Overclock Live Manager${NC}"
        echo -e "5) ${B_GREEN}Launch Wake-on-LAN Manager${NC}"
        echo ""
        echo -e "${CYAN}--- Governor Service Management ---${NC}"
        echo ""
        echo -e "${B_RED}--- WARNING: OVERCLOCKING AND UNDERVOLTING CAN DAMAGE YOUR HARDWARE! PROCEED ENTIRELY AT YOUR OWN RISK ---${NC}"
        echo ""
        echo -e "${YELLOW} Before you continue, make sure you make your changes to your config.toml file located at the following path \"/etc/cyan-skillfish-governor-smu/\"${NC}"
        echo ""
        echo -e "a) ${GREEN}Temporary Start${NC} (cyan-skillfish-governor-smu)"
        echo -e "b) ${B_GREEN}Permanent Start${NC} --now (cyan-skillfish-governor-smu)"
        echo -e "c) ${YELLOW}Restart Service${NC} (cyan-skillfish-governor-smu)"
        echo -e "d) ${RED}Temporary Stop${NC} (cyan-skillfish-governor-smu)"
        echo -e "e) ${B_RED}Stop and Disable Service${NC} --now (cyan-skillfish-governor-smu)"
        echo -e "f) ${CYAN}Verify Service Status${NC} (cyan-skillfish-governor-smu) ${RED}Press: Ctrl-c to return to Menu"${NC}
        echo ""
        echo -e "0) ${RED}Exit"${NC}
        echo ""
        echo -e "${CYAN}------------------------------------------${NC}"
        echo -e "${YELLOW} This Bazzite optimization script for the BC-250 SBC does the following: "
        echo "    • Enable the filippor-bazzite COPR repo "
        echo "    • Install cyan-skillfish-governor-smu (Enhanced Overclocking Version) "
        echo "    • Stop & disable oberon-governor and standard cyan-skillfish-governor "
        echo "    • Disable CPU mitigations and enable zswap "
        echo "    • Create a swapfile (16GB or 32GB depending on script of choice) "
        echo "    • Enable lighter swap compression (lz4) "
        echo "    • Set vm.swappiness = 180 "
        echo -e "    • Disable zram ${NC}"
        echo ""
        echo -e "${YELLOW}The only difference between these scripts is the swapfile size. If you have a large NVMe storage solution then just go with 32GB. However, if you only have a small drive, then wasting 32GB could be a tall order, so use the 16GB script. I haven't done enough testing to see if there is any performance impact. Choose wisely :) Do you take the ${B_RED}Red Pill${YELLOW}, or the ${B_BLUE}Blue Pill${YELLOW}?${NC}"
        echo -e "${CYAN}------------------------------------------${NC}"

        # Prompt user for input
        read -rp "Enter choice [1-f or 0 to exit ]: " choice

        case $choice in
            1)
                install_blue_pill
                ;;
            2)
                install_red_pill
                ;;
            3)
                apply_acpi_fix
                ;;
            4)
                install_overclock
                ;;
            5)
                install_wake_on_lan
                ;;
            a)
                echo -e "${GREEN}Executing Temporary Start...${NC}"
                sudo systemctl start cyan-skillfish-governor-smu
                sleep 2
                ;;
            b)
                echo -e "${B_GREEN}Executing Permanent Start...${NC}"
                sudo systemctl enable --now cyan-skillfish-governor-smu
                sleep 2
                ;;
            c)
                echo -e "${YELLOW}Executing Restart Service...${NC}"
                sudo systemctl restart cyan-skillfish-governor-smu
                sleep 2
                ;;
            d)
                echo -e "${RED}Executing Temporary Stop...${NC}"
                sudo systemctl stop --now cyan-skillfish-governor-smu
                sleep 2
                ;;
            e)
                echo -e "${B_RED}Executing Stop and Disable Service...${NC}"
                sudo systemctl disable --now cyan-skillfish-governor-smu
                sleep 2
                ;;
            f)
                clear
                echo -e "${CYAN}Displaying Service Status...${NC} ${RED}( Press Ctrl-c to continue )${NC}"
                sudo systemctl status cyan-skillfish-governor-smu
                echo ""
                read -rp "Press [Enter] to return to the main menu..."
                ;;
            0)
                echo -e "${GREEN}Exiting Bazzite Toolbox. Cleaning environment...${NC}"
            sleep 1

            # FIX: Send a hangup signal to parent terminal wrapper to kill the Konsole window
            if [ -n "$PPID" ]; then
                kill -SIGHUP "$PPID" 2>/dev/null
            fi
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice! Please select a valid number.${NC}"
            sleep 1.5
        esac
    done
}

# Start the menu loop execution
show_menu
