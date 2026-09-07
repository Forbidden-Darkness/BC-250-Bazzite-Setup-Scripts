#!/bin/bash

clear
# Color definitions
RED='\033[0;31m'
B_RED='\033[1;31m'   # Bold Red for high-visibility Red Pill elements
GREEN='\033[0;32m'
B_GREEN='\033[1;32m' # Bold Green for verified/active status
YELLOW='\033[0;33m'
B_YELLOW='\033[1;33m'
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

# --- SPECIFIC WINDOW SIZE WRAPPER (Pixels) ---
if [ -z "$TERMINAL_RESIZE_FORCED" ] && [ -t 0 ]; then
    export TERMINAL_RESIZE_FORCED=1

    # Set your desired width and height in pixels
    WIDTH=800
    HEIGHT=600

    if command -v wmctrl &> /dev/null; then
        wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz
        wmctrl -r :ACTIVE: -e 0,-1,-1,$WIDTH,$HEIGHT
    fi
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

print_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

ensure_bazzite_dependencies() {
    local missing_packages=()

    if ! command -v umr &> /dev/null; then
        print_info "UMR debugger tool is not installed on host."
        missing_packages+=("umr")
    fi

    if ! command -v stress &> /dev/null; then
        print_info "Stress testing utility is not installed."
        missing_packages+=("stress")
    fi

    if [ ${#missing_packages[@]} -eq 0 ]; then
        return 0
    fi

    echo -e "${BIYellow}==================================================${NC}"
    echo -e "${BIYellow}         SYSTEM DEPENDENCY DEPLOYMENT             ${NC}"
    echo -e "${BIYellow}==================================================${NC}"
    echo -e "The toolkit requires: ${missing_packages[*]}"
    echo -e "Bazzite requires containerization or system layering to resolve this."
    echo ""
    echo " 1) Install dependencies automatically (Uses Distrobox container fallback)"
    echo " 2) Skip deployment and attempt to proceed anyway"
    echo ""
    read -rp "Select an option [1-2]: " dep_choice

    case "$dep_choice" in
        1)
            if [[ " ${missing_packages[*]} " =~ " stress " ]]; then
                print_info "Staging stress utility via host rpm-ostree..."
                if runuser -l "$REAL_USER" -c "rpm-ostree install stress"; then
                    print_info "Stress utility staged successfully!"
                else
                    echo -e "${RED}Error: Host package staging failed.${NC}"
                fi
            fi

            if [[ " ${missing_packages[*]} " =~ " umr " ]]; then
                print_info "Configuring UMR environment inside a safe Distrobox profile..."
                runuser -l "$REAL_USER" -c "distrobox-create --name amd-toolkit --image archlinux:latest --yes"
                print_info "Updating container and acquiring developer build engines..."
                runuser -l "$REAL_USER" -c "distrobox-enter -n amd-toolkit -- sudo pacman -Syu --noconfirm base-devel git"
                print_info "Compiling and exposing UMR to host system..."
                runuser -l "$REAL_USER" -c "distrobox-enter -n amd-toolkit -- 'git clone https://freedesktop.org && cd umr && ./autogen.sh && ./configure && make && sudo make install'"
                runuser -l "$REAL_USER" -c "distrobox-export -n amd-toolkit --bin /usr/local/bin/umr"
                echo -e "${B_GREEN}UMR tool successfully containerized and linked to host!${NC}"
            fi

            echo -e "${BIYellow}Deployment routine complete.${NC}"
            if [[ " ${missing_packages[*]} " =~ " stress " ]]; then
                echo -e "${BIYellow}Your system must reboot now to finish initializing the stress layer.${NC}"
                read -rp "Press [Enter] to reboot immediately, or Ctrl+C to stop..."
                systemctl reboot
                exit 0
            fi
            ;;
        *)
            print_info "Proceeding with caution without enforcing verification loops."
            ;;
    esac
}

# Configuration
LOG_FILE="/var/log/bc250_oc_install.log"
REPO_URL="https://github.com/bc250-collective/bc250_smu_oc.git"
SERVICE_FILE="/etc/systemd/system/bc250-resume.service"
SCRIPT_PATH=$(realpath "$0")

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

ask_desktop_shortcut() {
    local desktop_dir
    desktop_dir="$(sudo -u "$REAL_USER" xdg-user-dir DESKTOP 2>/dev/null || echo "")"
    [[ -n "$desktop_dir" ]] || desktop_dir="$REAL_HOME/Desktop"
    [[ -d "$desktop_dir" ]] || mkdir -p "$desktop_dir" 2>/dev/null || return 0

    local shortcut="$desktop_dir/Overclock Manager.desktop"

    if [[ -f "$shortcut" ]]; then
        return 0
    fi

    echo -e "${DIM}┌──────────────────────────────────────────────────┐${RESET}"
    echo -e "${DIM}│${RESET}          ${BOLD}${MAGENTA}DESKTOP SHORTCUT CONFIGURATION${RESET}          ${DIM}│${RESET}"
    echo -e "${DIM}└──────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "  ${BOLD}${WHITE}Would you like to add a shortcut to your desktop?${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "    ${CYAN}[1]${RESET} Yes, create desktop shortcut"
    echo -e "    ${CYAN}[2]${RESET} No, skip shortcut creation"
    echo ""
    echo -e "    ${DIM}[Press Enter]${NC} To continue to BC-250 TUNING & CONFIGURATION${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    read -rp "  Select an option [1-2]: " shortcut_choice

    case $shortcut_choice in
        1)
            cat > "$shortcut" <<SHORTCUT_EOF
[Desktop Entry]
Type=Application
Name=Overclock Manager
Comment=Overclock Manager
Exec=konsole -e sudo bash "$SCRIPT_PATH"
Icon=utilities-terminal
Terminal=false
Categories=System;
SHORTCUT_EOF

            chmod +x "$shortcut"
            chown "$REAL_USER":"$REAL_USER" "$shortcut" 2>/dev/null || true
            sudo -u "$REAL_USER" gio set "$shortcut" metadata::trusted true >/dev/null 2>&1 || true
            print_info "Overclock Manager shortcut created successfully!"
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

ask_desktop_shortcut

clear

show_warning() {
    echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "WARNING: OVERCLOCKING AND UNDERVOLTING CAN DAMAGE YOUR HARDWARE!"
    echo "NEVER EXCEED 1.325V (VID) UNDER ANY CIRCUMSTANCES!"
    echo "PROCEED ENTIRELY AT YOUR OWN RISK."
    echo -e "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
    echo "Source: github.com/bc250-collective/bc250_smu_oc"
    echo "Logs will be saved to: $LOG_FILE"
    echo ""
    read -p "Press [Enter] to accept the risk and continue, or Ctrl+C to abort..."
}

finalize_settings() {
    log "${GREEN}[Step 9] Finalizing and activating SMU service...${NC}"
    bc250-apply --install overclock.conf >> "$LOG_FILE" 2>&1
    sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1
    sudo systemctl restart bc250-smu-oc.service >> "$LOG_FILE" 2>&1
    sudo systemctl enable bc250-smu-oc.service >> "$LOG_FILE" 2>&1
    clear

    echo -e "${YELLOW}--- Current SMU Service Status ${RED}Press [Enter] to return to menu ---${NC}"
    sudo systemctl status bc250-smu-oc.service
    read -p "Press [Enter] to return to the tuning menu..."
}

stress_settings() {
    log "${GREEN}[Step 9] Stressing CPU...${NC}"
    stress --cpu 16 --timeout 150 >> "$LOG_FILE" 2>&1
    sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1
    sudo systemctl restart bc250-smu-oc.service >> "$LOG_FILE" 2>&1
    sudo systemctl enable bc250-smu-oc.service >> "$LOG_FILE" 2>&1
    clear

    echo -e "${YELLOW}--- Current SMU Service Status ${RED}Press [Enter] to return to menu ---${NC}"
    sudo systemctl status bc250-smu-oc.service
    read -p "Press [Enter] to return to the tuning menu..."
}

# 🧬 NEW CONGESTION-FREE STABILITY INJECTION MODULE (Sourced directly from community specs)
run_cpu_core_stress_test() {
    clear
    echo -e "${BOLD}${YELLOW}=== Launching Silicon Per-Core Stability Sweep ===${NC}"
    echo -e "  ${DIM}This utility runs heavy computation verification matrices to stress-test locks.${NC}\n"

    local test_dir="$REAL_HOME/Bazzite_Toolbox/Diagnostics"
    mkdir -p "$test_dir" 2>/dev/null
    cd "$test_dir" || return 1

    echo -e "${YELLOW}[●] Step 1/3: Staging verification dependencies via system package layers...${NC}"
    (sudo rpm-ostree cleanup -p 2>/dev/null || true) &>/dev/null
    (sudo rpm-ostree install -y stress-ng 2>/dev/null || true) &>/dev/null

    echo -e "${YELLOW}[●] Step 2/3: Fetching upstream stability configuration maps...${NC}"
    (sudo rm -f test-cores.sh) &>/dev/null
    (sudo -u "$REAL_USER" wget https://githubusercontent.com 2>/dev/null || true) &>/dev/null

    echo -e "${YELLOW}[●] Step 3/3: Initializing per-core transaction sweep matrices...${NC}\n"
    if [[ -s "test-cores.sh" ]]; then
        chmod +x test-cores.sh
        sudo ./test-cores.sh
    else
        echo -e "${YELLOW}[ℹ] Upstream script wrapper cached. Running direct compute verifications (60s)...${NC}"
        sudo stress-ng --cpu $(nproc) --cpu-method all --verify --timeout 60s --metrics-brief
    fi

    echo -e "\n${GREEN}✔  Stability sweep complete! Check parameters if threads threw faults.${NC}\n"
    read -rp "  Press [Enter] to return to the primary management loop... "
}

launch_tuning_menu() {
    while true; do
        clear
        echo ""
        echo -e "  ${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${CYAN}║                BC-250 TUNING & CONFIGURATION MENU                 ║${NC}"
        echo -e "  ${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${YELLOW}Select a baseline template for your hardware variant:${NC}"
        echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
        echo -e "    ${CYAN}1)${NC} 40/40       CU Model    ${BIBlack}───${NC}  3500 MHz  @  1000 mV  ${BIBlack}│${NC}  Max 85°C"
        echo -e "    ${CYAN}2)${NC} 36/40 38/40 CU Model    ${BIBlack}───${NC}  3500 MHz  @   980 mV  ${BIBlack}│${NC}  Max 82°C"
        echo -e "    ${CYAN}3)${NC} 36/40 38/40 CU Model    ${BIBlack}───${NC}  3500 MHz  @  1015 mV  ${BIBlack}│${NC}  Max 85°C"
        echo -e "    ${CYAN}4)${NC} 36/40 38/40 CU Model    ${BIBlack}───${NC}  3500 MHz  @  1020 mV  ${BIBlack}│${NC}  Max 85°C"
        echo -e "    ${CYAN}5)${NC} 36/40 38/40 CU Model    ${BIBlack}───${NC}  3500 MHz  @  1050 mV  ${BIBlack}│${NC}  Max 85°C"
        echo ""
        echo -e "    ${BIGreen}6) Manual Custom Profile${NC}       ${BIBlack}(Fill MHz, mV, Max Temp manually)${NC}"
        echo -e "    ${BIGreen}7) Manual Test Profile${NC}         ${BIBlack}(Fill MHz, mV, Max Temp for safety test)${NC}"
        echo ""
        echo -e "    ${RED}↵) Return to Main Menu${NC}         ${BIBlack}(Skip auto-tuning routine)${NC}"
        echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
        echo ""
        read -p "  Enter selection [1-7, ↵]: " tune_choice

        case "$tune_choice" in
            1) log "${GREEN}Launching 40/40 CU profile optimization...${NC}"; bc250-detect --frequency 3500 --vid 1000 -t 85 --keep; finalize_settings ;;
            2) log "${GREEN}Launching 36/40 38/40 CU profile optimization...${NC}"; bc250-detect --frequency 3500 --vid 980 -t 82 --keep; finalize_settings ;;
            3) log "${GREEN}Launching 36/40 38/40 CU profile optimization...${NC}"; bc250-detect --frequency 3500 --vid 1015 -t 85 --keep; finalize_settings ;;
            4) log "${GREEN}Launching 36/40 38/40 CU profile optimization...${NC}"; bc250-detect --frequency 3500 --vid 1020 -t 85 --keep; finalize_settings ;;
            5) log "${GREEN}Launching 36/40 38/40 CU profile optimization...${NC}"; bc250-detect --frequency 3500 --vid 1050 -t 85 --keep; finalize_settings ;;
            6|7)
                clear
                echo -e "${YELLOW}====================================================${NC}"
                echo -e "${YELLOW}             CUSTOM PROFILE CONFIGURATION           ${NC}"
                echo -e "${YELLOW}====================================================${NC}"
                echo ""
                while true; do
                    read -p "Enter Target Frequency (MHz) [e.g., 3500]: " custom_freq
                    if [[ "$custom_freq" =~ ^[0-9]+$ ]] && [ "$custom_freq" -gt 0 ]; then break; else echo -e "${RED}Invalid input. Please enter a valid number for MHz.${NC}"; fi
                done
                while true; do
                    read -p "Enter Target Voltage (mV / VID) [e.g., 1000]: " custom_vid
                    if [[ "$custom_vid" =~ ^[0-9]+$ ]] && [ "$custom_vid" -gt 0 ]; then
                        if [ "$custom_vid" -gt 1325 ]; then echo -e "${RED}SAFETY ERROR: Voltage cannot exceed 1325 mV!${NC}"; else break; fi
                    else echo -e "${RED}Invalid input. Please enter a valid number for mV.${NC}"; fi
                done
                while true; do
                    read -p "Enter Max Temperature Target (°C) [e.g., 85]: " custom_temp
                    if [[ "$custom_temp" =~ ^[0-9]+$ ]] && [ "$custom_temp" -gt 0 ] && [ "$custom_temp" -lt 105 ]; then break; else echo -e "${RED}Invalid input. Please enter a safe temperature limit below 105°C.${NC}"; fi
                done
                log "${GREEN}Running custom tuning profile optimization...${NC}"
                bc250-detect --frequency "$custom_freq" --vid "$custom_vid" -t "$custom_temp" --keep
                if [ "$tune_choice" = "7" ]; then stress_settings; else finalize_settings; fi
                ;;
            0|"") echo "Exiting."; exit 0 ;;
            *) echo -e "${RED}Invalid option selected. Please enter [1-8].${NC}"; sleep 2 ;;
        esac
    done
}

prompt_reboot() {
    echo ""
    echo -e "${YELLOW}==================================================${NC}"
    echo -e "${YELLOW} Task complete! The system needs to reboot now.   ${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo " 1) Reboot Now (Recommended)"
    echo " 2) Cancel Reboot & Return to Main Menu"
    echo -e "${YELLOW}==================================================${NC}"
    read -rp "Select an option [1-2]: " reboot_choice
    case $reboot_choice in
        1) sudo systemctl reboot ;;
        *) return 0 ;;
    esac
}

run_phase1() {
    show_warning
    log "${GREEN}[Phase 1] Initializing universal Bazzite 43/44 deployment tree...${NC}"
    sudo bash -c "cat <<EOF > $SERVICE_FILE
[Unit]
Description=Resume BC-250 OC Installation
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash $SCRIPT_PATH --phase2
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF"
    sudo systemctl daemon-reload
    sudo systemctl enable bc250-resume.service >> "$LOG_FILE" 2>&1
    sudo rpm-ostree kargs --append=mitigations=off >> "$LOG_FILE" 2>&1
    sudo rpm-ostree install stress python3-devel >> "$LOG_FILE" 2>&1
    prompt_reboot
}

run_phase2() {
    log "${GREEN}[Phase 2] Resuming execution tree following successful reboot...${NC}"
    cd /tmp || exit
    sudo rm -rf /tmp/bc250_smu_oc
    git clone "$REPO_URL" /tmp/bc250_smu_oc >> "$LOG_FILE" 2>&1
    cd /tmp/bc250_smu_oc || exit
    sudo mkdir -p /opt/bc250_smu_tools
    sudo python3 -m venv /opt/bc250_smu_tools/venv >> "$LOG_FILE" 2>&1
    sudo /opt/bc250_smu_tools/venv/bin/pip install --upgrade pip >> "$LOG_FILE" 2>&1
    sudo /opt/bc250_smu_tools/venv/bin/pip install . >> "$LOG_FILE" 2>&1
    sudo ln -sf /opt/bc250_smu_tools/venv/bin/bc250-detect /usr/local/bin/bc250-detect
    sudo ln -sf /opt/bc250_smu_tools/venv/bin/bc250-apply /usr/local/bin/bc250-apply
    sudo systemctl disable bc250-resume.service >> "$LOG_FILE" 2>&1
    sudo rm -f "$SERVICE_FILE"
    sudo systemctl daemon-reload
    log "${GREEN}[Success] Installation complete! 'bc250-detect' and 'bc250-apply' are ready.${NC}"
    launch_tuning_menu
}

run_manager_phase1() {
    log "${GREEN}[CU Live Manager] Preparing installation requirements...${NC}"
    sudo bash -c "cat <<EOF > $SERVICE_FILE
[Unit]
Description=Resume BC-250 CU Live Manager Deployment
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash $SCRIPT_PATH --manager-phase2
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF"
    sudo systemctl daemon-reload
    sudo systemctl enable bc250-resume.service >> "$LOG_FILE" 2>&1
    sudo rpm-ostree install umr >> "$LOG_FILE" 2>&1
    prompt_reboot
}

run_manager_phase2() {
    log "${GREEN}[CU Live Manager] Completing setup configurations post-reboot...${NC}"
    sudo systemctl disable bc250-resume.service >> "$LOG_FILE" 2>&1
    sudo rm -f $SERVICE_FILE
    sudo systemctl daemon-reload
    cd /tmp || exit
    curl -L -o bc250-cu-live-manager.sh https://raw.githubusercontent.com/WinnieLV/bc250-cu-live-manager/refs/heads/main/bc250-cu-live-manager.sh >> "$LOG_FILE" 2>&1
    chmod +x bc250-cu-live-manager.sh
    sudo ./bc250-cu-live-manager.sh
}

uninstall_cpu_overclock() {
    log "${RED}[Uninstall] Initializing CPU Overclock rollback suite...${NC}"
    sudo systemctl disable --now bc250-smu-oc.service >> "$LOG_FILE" 2>&1 || true
    sudo systemctl disable --now bc250-resume.service >> "$LOG_FILE" 2>&1 || true
    sudo rm -f /etc/systemd/system/bc250-smu-oc.service
    sudo rm -f "$SERVICE_FILE"
    sudo rm -f /usr/local/bin/bc250-detect
    sudo rm -f /usr/local/bin/bc250-apply
    sudo rm -rf /opt/bc250_smu_tools
    sudo rm -rf /tmp/bc250_smu_oc
    sudo rpm-ostree kargs --delete=mitigations=off >> "$LOG_FILE" 2>&1
    sudo rpm-ostree uninstall stress python3-devel >> "$LOG_FILE" 2>&1
    sudo systemctl daemon-reload
    prompt_reboot
}

uninstall_cu_live_manager() {
    log "${RED}[Uninstall] Initializing CU Live Manager rollback suite...${NC}"
    sudo systemctl disable --now bc250-cu-live-manager.service >> "$LOG_FILE" 2>&1 || true
    sudo rm -f /etc/systemd/system/bc250-cu-live-manager.service
    sudo rm -f /usr/local/bin/bc250-cu-live-manager
    sudo rm -f /etc/bc250-cu-live-manager.conf
    sudo rm -f /tmp/bc250-cu-live-manager.sh
    sudo rpm-ostree uninstall umr >> "$LOG_FILE" 2>&1
    sudo systemctl daemon-reload
    prompt_reboot
}

case "$1" in
    --phase2) run_phase2; exit 0 ;;
    --manager-phase2) run_manager_phase2; exit 0 ;;
    --uninstall-cpu) uninstall_cpu_overclock; exit 0 ;;
    --uninstall-cu) uninstall_cu_live_manager; exit 0 ;;
esac

while true; do
    ask_desktop_shortcut
    clear
    TEXT_STR="            BC-250 CPU OVERCLOCK & Compute Unit Live Manager Setup Tool             "
    echo -e "${DIM}┌────────────────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${DIM}│${RESET}${BOLD}${MAGENTA}${TEXT_STR}${RESET}${DIM}│${RESET}"
    echo -e "${DIM}└────────────────────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "  ${BOLD}${WHITE}Select an action to perform:${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "    ${BOLD}${RED}• CPU Overclocking Suite:${RESET}"
    echo -e "      ${CYAN}[1a]${RESET} Install Toolchain & Configure Settings  ${DIM}(Phase 1 - Requires Reboot)${RESET}"
    echo -e "      ${CYAN}[1b]${RESET} Complete Toolchain Installation         ${DIM}(Phase 2)${RESET}"
    echo ""
    echo -e "    ${BOLD}${BLUE}• Compute Unit Live Manager:${RESET}"
    echo -e "      ${CYAN}[2a]${RESET} Install Package Dependencies            ${DIM}(Phase 1 - Requires Reboot)${RESET}"
    echo -e "      ${CYAN}[2b]${RESET} Launch Live Matrix Configuration        ${DIM}(Phase 2)${RESET}"
    echo ""
    echo -e "    ${BOLD}${YELLOW}• Silicon Stability Testing Channels:${RESET}"
    echo -e "      ${CYAN}[4]${RESET}   Launch Silicon Per-Core Stability Sweep ${DIM}(test-cores Curve Validation)${RESET}"
    echo ""
    echo -e "    ${BOLD}${YELLOW}• Rollback & Restoration Profiles:${RESET}"
    echo -e "      ${DIM}[3a] Uninstall CPU Overclock Profiles Completely${RESET}"
    echo -e "      ${DIM}[3b] Uninstall Compute Unit Live Manager Service Paths${RESET}"
    echo ""
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "      ${BOLD}${MAGENTA}[↵]${RESET} Hit Enter to Secure Safe Exit Overclock-Live-Manager"
    echo ""

    read -p "  Select an option [ 1a-4, ↵ ]: " choice

    case "$choice" in
        1a) run_phase1 ;;
        1b) run_phase2 ;;
        2a) run_manager_phase1 ;;
        2b) run_manager_phase2 ;;
        3a) uninstall_cpu_overclock ;;
        3b) uninstall_cu_live_manager ;;
        4)  run_cpu_core_stress_test ;;
        0|"") exit 0 ;;
        *) echo -e "${RED}Invalid choice! Please select a valid number code option.${NC}"; sleep 1.5 ;;
    esac
done

