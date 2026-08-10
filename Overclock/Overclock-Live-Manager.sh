#!/bin/bash

clear
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
B_VIOLET='\033[1;35m'
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White
NC='\033[0m'

# Verify root/sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run with sudo or as root."
    echo -e "Please run: sudo bash $0${NC}"
    exit 1
fi
# Configuration
LOG_FILE="/var/log/bc250_oc_install.log"
REPO_URL="https://github.com/bc250-collective/bc250_smu_oc.git"
SERVICE_FILE="/etc/systemd/system/bc250-resume.service"
SCRIPT_PATH=$(realpath "$0")

# Logger function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Warning message reflecting official repository safety parameters
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

# Post-Detection Finalization Function
finalize_settings() {
    log "${GREEN}[Step 9] Finalizing and activating SMU service...${NC}"
    bc250-apply --install overclock.conf >> "$LOG_FILE" 2>&1
    sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1
    sudo systemctl restart bc250-smu-oc.service >> "$LOG_FILE" 2>&1
    sudo systemctl enable bc250-smu-oc.service >> "$LOG_FILE" 2>&1
    clear

    echo -e "${YELLOW}--- Current SMU Service Status ${RED}Ctrl+c then press enter to return to menu ---${NC}"
    sudo systemctl status bc250-smu-oc.service
    read -p "Press [Enter] to return to the tuning menu..."

    #echo -e "${YELLOW}--- Current SMU Service Status ---${NC}"
    #sudo systemctl status bc250-smu-oc.service
    #read -p "Press [Enter] to return to the tuning menu..."
}

# Interactive Tuning Menu (Fixed and cleanly looping back to main menu loop)
launch_tuning_menu() {
    while true; do
        clear
        echo ""
        echo -e "${YELLOW}====================================================${NC}"
        echo -e "${YELLOW}          BC-250 TUNING & CONFIGURATION MENU       ${NC}"
        echo -e "${YELLOW}====================================================${NC}"
        echo "Select a baseline template for your hardware variant:"
        echo "1) 40CU Model    (3500 MHz @ 1000 mV, Max 85°C)"
        echo "2) 36/38CU Model (3500 MHz @ 980 mV, Max 82°C)"
        echo "3) 36/38CU Model (3500 MHz @ 1015 mV, Max 85°C)"
        echo "4) 36/38CU Model (3500 MHz @ 1020 mV, Max 85°C)"
        echo "5) Skip auto-tuning (Return to Main Menu)"
        echo ""
        read -p "Enter selection [1-4]: " tune_choice

        case "$tune_choice" in
            1)
                log "${GREEN}Launching 40CU profile optimization...${NC}"
                bc250-detect --frequency 3500 --vid 1000 -t 85 --keep
                finalize_settings
                break
                ;;
            2)
                log "${GREEN}Launching 36/38CU profile optimization...${NC}"
                bc250-detect --frequency 3500 --vid 980 -t 82 --keep
                finalize_settings
                break
                ;;
            3)
                log "${GREEN}Launching 36/38CU profile optimization...${NC}"
                bc250-detect --frequency 3500 --vid 1015 -t 85 --keep
                finalize_settings
                break
                ;;
            4)
                log "${GREEN}Launching 36/38CU profile optimization...${NC}"
                bc250-detect --frequency 3500 --vid 1020 -t 85 --keep
                finalize_settings
                break
                ;;
            5)
                log "${YELLOW}Skipped auto-tuning. Returning to main menu.${NC}"
                break
                ;;
            *)
                echo -e "${RED}Invalid option. Please enter 1, 2, or 4.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Phase 1: Initial Install
run_phase1() {
    show_warning
    log "${GREEN}[Phase 1] Starting setup...${NC}"

    log "${GREEN}[Step 1] Creating temporary resume service...${NC}"
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

    log "${GREEN}[Step 2] Appending CPU mitigation kernel arguments...${NC}"
    sudo rpm-ostree kargs --append=mitigations=off >> "$LOG_FILE" 2>&1

    log "${GREEN}[Step 3] Installing dependencies via rpm-ostree...${NC}"
    sudo rpm-ostree install stress pipx >> "$LOG_FILE" 2>&1

    log "${RED}[Step 4] Rebooting system. Script will resume automatically...${NC}"
    sudo systemctl reboot
}

# Phase 2: Post-Reboot Execution
run_phase2() {
    log "${GREEN}[Phase 2] Resuming setup after reboot...${NC}"

    log "${GREEN}[Step 5] Ensuring pipx path...${NC}"
    pipx ensurepath >> "$LOG_FILE" 2>&1
    export PATH="$HOME/.local/bin:$PATH"

    log "${GREEN}[Step 6] Verifying pipx...${NC}"
    pipx --version >> "$LOG_FILE" 2>&1

    log "${GREEN}[Step 7] Cloning repo and installing SMU tool...${NC}"
    cd /tmp || exit
    sudo rm -rf /tmp/bc250_smu_oc

    git clone "$REPO_URL" /tmp/bc250_smu_oc >> "$LOG_FILE" 2>&1
    cd /tmp/bc250_smu_oc || exit

    # Run pipx install locally within the verified absolute path
    pipx install . >> "$LOG_FILE" 2>&1

    log "${GREEN}[Step 8] Cleaning up temporary automation service...${NC}"
    sudo systemctl disable bc250-resume.service >> "$LOG_FILE" 2>&1
    sudo rm -f $SERVICE_FILE
    sudo systemctl daemon-reload

    log "${GREEN}[Success] Installation complete! 'bc250-detect' and 'bc250-apply' are ready.${NC}"

    # Trigger the hardware template selection menu
    launch_tuning_menu
}

# CU Live Manager Phase 1: Dependency Setup
run_manager_phase1() {
    log "${GREEN}[CU Live Manager] Preparing installation requirements...${NC}"

    log "${GREEN}[Step 1] Initializing temporary manager boot loader...${NC}"
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

    log "${GREEN}[Step 2] Staging core 'umr' package tracking layers via rpm-ostree...${NC}"
    sudo rpm-ostree install umr >> "$LOG_FILE" 2>&1

    log "${RED}[Step 3] Rebooting system. Execution environment will resume on startup...${NC}"
    sudo systemctl reboot
}

# CU Live Manager Phase 2: Launch Routine
run_manager_phase2() {
    log "${GREEN}[CU Live Manager] Completing setup configurations post-reboot...${NC}"

    log "${GREEN}[Step 4] Cleaning background persistence components...${NC}"
    sudo systemctl disable bc250-resume.service >> "$LOG_FILE" 2>&1
    sudo rm -f $SERVICE_FILE
    sudo systemctl daemon-reload

    log "${GREEN}[Step 5] Fetching live manager controller execution script...${NC}"
    cd /tmp || exit
    curl -L -o bc250-cu-live-manager.sh https://raw.githubusercontent.com/WinnieLV/bc250-cu-live-manager/refs/heads/main/bc250-cu-live-manager.sh >> "$LOG_FILE" 2>&1
    chmod +x bc250-cu-live-manager.sh

    log "${GREEN}[Step 6] Transferring shell execution context directly to live manager profile...${NC}"
    sudo ./bc250-cu-live-manager.sh
}

# Rollback / Uninstall Routine
run_uninstall() {
    log "${RED}[Uninstall] Starting rollback process...${NC}"

    log "${RED}[1/6] Disabling startup services...${NC}"
    sudo systemctl disable bc250-smu-oc >> "$LOG_FILE" 2>&1
    sudo systemctl disable bc250-resume.service >> "$LOG_FILE" 2>&1
    sudo rm -f $SERVICE_FILE
    sudo systemctl daemon-reload

    log "${RED}[2/6] Removing CPU mitigation kernel arguments...${NC}"
    sudo rpm-ostree kargs --delete=mitigations=off >> "$LOG_FILE" 2>&1

    log "${RED}[3/6] Removing pipx tool...${NC}"
    pipx uninstall bc250_smu_oc >> "$LOG_FILE" 2>&1

    log "${RED}[4/6] Removing toolchain and manager engine packages via rpm-ostree...${NC}"
    sudo rpm-ostree uninstall stress pipx umr >> "$LOG_FILE" 2>&1

    log "${RED}[5/6] Cleaning transient directory paths...${NC}"
    sudo rm -f /tmp/bc250-cu-live-manager.sh
    sudo rm -rf /tmp/bc250_smu_oc

    log "${GREEN}[6/6] Uninstall complete. Rebooting to clear packages and re-enable mitigations...${NC}"
    sudo systemctl reboot
}

# Main script logic handles direct commands or initializes main loop
case "$1" in
    --phase2)
        run_phase2
        exit 0
        ;;
    --manager-phase2)
        run_manager_phase2
        exit 0
        ;;
    --uninstall)
        run_uninstall
        exit 0
        ;;
esac

# Persistent Main Menu Loop
while true; do
    clear
    echo -e "${YELLOW}====================================================================================${NC}"
    echo -e "${YELLOW}            BC-250 CPU OVERCLOCK & Compute Unite Live Manager Setup Tool            ${NC}"
    echo -e "${YELLOW}====================================================================================${NC}"
    echo ""
    echo "Select an action to perform:"
    echo ""
    echo -e "${BIRed}1) CPU Overclock Install toolchain & configure settings (Phase 1 - Requires Reboot)${NC}"
    echo -e "${BIRed}2) CPU Overclock Complete toolchain installation (Phase 2)${NC}"
    echo -e "${BIBlue}3) Install Compute Unite Live Manager Dependencies (Phase 1 - Requires Reboot)${NC}"
    echo -e "${BIBlue}4) Launch Compute Unite Live Manager Configuration (Phase 2)${NC}"
    echo ""
    echo "5) Rollback: Running ./setup_oc.sh --uninstall"
    echo "6) Exit"
    echo ""
    read -p "Enter selection [1-6]: " choice

    if [ "$choice" == "1" ]; then
        run_phase1
    elif [ "$choice" == "2" ]; then
        run_phase2
    elif [ "$choice" == "3" ]; then
        run_manager_phase1
    elif [ "$choice" == "4" ]; then
        run_manager_phase2
    elif [ "$choice" == "5" ]; then
        run_uninstall
    elif [ "$choice" == "6" ] || [ -z "$choice" ]; then
        echo "Exiting."
        exit 0
    else
    echo "Invalid choice. Please choose between 1 and 6."
            sleep 2
        fi
        done
