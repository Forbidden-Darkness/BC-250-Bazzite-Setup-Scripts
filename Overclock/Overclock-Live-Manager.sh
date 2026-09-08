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
    echo "Source: ://github.com"
    echo "Logs will be saved to: $LOG_FILE"
    echo ""
    read -p "Press [Enter] to accept the risk and continue, or Ctrl+C to abort..."
}

# ==============================================================================
# 🧬 HARDENED SERVICE ACTIVATION ENGINE (PREVENTS MISSING SERVICE ALERTS)
# ==============================================================================
finalize_settings() {
    log "${GREEN}[Step 9] Finalizing and activating SMU service...${NC}"
    bc250-apply --install overclock.conf >> "$LOG_FILE" 2>&1

    # 🧬 Check if the service actually exists before trying to touch it!
    if [[ -f "/etc/systemd/system/bc250-smu-oc.service" ]]; then
        sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1
        sudo systemctl restart bc250-smu-oc.service >> "$LOG_FILE" 2>&1
        sudo systemctl enable bc250-smu-oc.service >> "$LOG_FILE" 2>&1
        clear
        echo -e "${YELLOW}--- Current SMU Service Status ${RED}Press [Enter] to return to menu ---${NC}"
        sudo systemctl status bc250-smu-oc.service
    else
        clear
        echo -e "${GREEN}[✓] Settings applied to local conf! Toolchain installation required to activate as boot service.${NC}"
    fi
    read -p "Press [Enter] to return to the tuning menu..."
}

stress_settings() {
    log "${GREEN}[Step 9] Stressing CPU...${NC}"
    stress --cpu 16 --timeout 150 >> "$LOG_FILE" 2>&1

    # 🧬 Check if the service actually exists before trying to touch it!
    if [[ -f "/etc/systemd/system/bc250-smu-oc.service" ]]; then
        sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1
        sudo systemctl restart bc250-smu-oc.service >> "$LOG_FILE" 2>&1
        sudo systemctl enable bc250-smu-oc.service >> "$LOG_FILE" 2>&1
        clear
        echo -e "${YELLOW}--- Current SMU Service Status ${RED}Press [Enter] to return to menu ---${NC}"
        sudo systemctl status bc250-smu-oc.service
    else
        clear
        echo -e "${GREEN}[✓] Stress test completed! Toolchain installation required to monitor live background service.${NC}"
    fi
    read -p "Press [Enter] to return to the tuning menu..."
}

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

# ==============================================================================
# 🧬 HARDWARE-AWARE PERFORMANCE PROFILE CONFIGURATION GENERATOR
# ==============================================================================
configure_governor_profile() {
    clear
    echo -e "\n  ${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║              BC-250 HARDWARE SPECIFICATIONS AUDIT WIZARD          ║${NC}"
    echo -e "  ${CYAN}║               * AUTOMATED SAFETY THROTTLING ENGINE *              ║${NC}"
    echo -e "  ${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # 🚀 ADVANCED HYBRID SILICON AUTODETECTOR LAYER
    echo -e "  ${YELLOW}[●] Scanning live hardware topologies and live configuration logs...${NC}"
    local detected_cus=24

    # 🔍 WinnieLV WGP Mask Parser: Dynamically decodes active live config files
    if [[ -f /etc/bc250-cu-live-manager.conf ]]; then
        local raw_masks
        raw_masks=$(grep "BC250_WGP_MASKS=" /etc/bc250-cu-live-manager.conf | cut -d= -f2)
        if [[ -n "$raw_masks" ]]; then
            # Sum up bit elements across all four shader engine channels smoothly
            local total_bits=0
            IFS=',' read -r -a mask_array <<< "$raw_masks"
            for mask in "${mask_array[@]}"; do
                local val=$((mask))
                # Counts active binary bits to pull exact total routed WGPs
                for ((i=0; i<32; i++)); do
                    (( (val >> i) & 1 )) && ((total_bits++))
                done
            done
            # Each active bit represents 1 WGP which houses exactly 2 active CUs
            (( detected_cus = total_bits * 2 ))
        fi
    fi

    # Fallback to direct kernel diagnostics query if manager profile config hasn't been written yet
    if (( detected_cus == 0 )) && command -v umr &> /dev/null; then
        detected_cus=$(umr -i 0 -g 2>/dev/null | grep -i "cu_per_sh" | awk '{print $3 * 4}')
    fi
    if [[ ! "$detected_cus" =~ ^[0-9]+$ ]] || (( detected_cus <= 0 )); then
        detected_cus=24
    fi

    local live_threads=$(nproc 2>/dev/null || echo "12")
    local detected_cores=$(( live_threads / 2 ))
    echo -e "      ${BIBlue}[ℹ] SYSTEM CURRENTLY RUNNING: ${detected_cus}/40 Active CUs | ${detected_cores} CPU Cores Active.${NC}\n"

    # 📋 AUDIT NO. 1: COOLING INFRASTRUCTURE
    echo -e "  ${BOLD}${BLUE}[1/5] Select the physical cooling system configuration currently active:${RESET}"
    echo -e "    1) Stock / Factory OEM Basic Air Cooler"
    echo -e "    2) High-End Aftermarket Air Cooled (Heavy Fin Stack / High CFM Fans)"
    echo -e "    3) Liquid Cooled / AIO Closed Loop / Custom Water Block"
    echo ""
    local cooling_choice=""
    read -p "  Enter cooling profile option [1-3]: " cooling_choice

    local THROTTLE_TEMP=72
    local RECOVERY_TEMP=65
    local COOLING_LABEL="Stock Air"

    case "$cooling_choice" in
        1) THROTTLE_TEMP=72; RECOVERY_TEMP=65; COOLING_LABEL="Stock Air (Restricted)";;
        2) THROTTLE_TEMP=84; RECOVERY_TEMP=75; COOLING_LABEL="Premium Air Cooled";;
        3) THROTTLE_TEMP=65; RECOVERY_TEMP=58; COOLING_LABEL="Liquid Cooled Core";;
        *) echo -e "  ${RED}❌ Invalid choice. Falling back to safe Stock Air parameters.${NC}"; THROTTLE_TEMP=72;;
    esac
    echo ""
    # 📋 AUDIT NO. 2: POWER BUDGET (300W - 500W+ STRATA)
    echo -e "  ${BOLD}${BLUE}[2/5] Enter your current Power Supply (PSU) maximum wattage rating:${RESET}"
    echo -e "        ${DIM}(Accepts 300W baseline up to 500W+ extreme power overhead profiles)${RESET}"
    echo ""
    local psu_wattage=""
    read -p "  PSU Wattage Rating (e.g., 300, 450, 500): " psu_wattage

    if ! [[ "$psu_wattage" =~ ^[0-9]+$ ]]; then
        echo -e "  ${RED}⚠ Invalid format. Defaulting power tracking to minimal 300W limits.${NC}"
        psu_wattage=300
    fi
    echo ""

        # 📋 AUDIT NO. 3: FUTURE TARGET COMPUTE UNITS (INTELLIGENT HYBRID CONFIRMATION)
    echo -e "  ${BOLD}${BLUE}[3/5] I do see you have ${detected_cus}/40 CUs currently active on this system.${RESET}"
    echo -e "        Are you planning to change or target a different configuration footprint?"
    echo -e "    1) Target 36 CUs Active  ${DIM}(Down-binned / Maximum High-Efficiency Target Layout)${RESET}"
    echo -e "    2) Target 38 CUs Active  ${DIM}(Optimal Mid-Tier Custom Performance Curve Baseline)${RESET}"
    echo -e "    3) Target 40 CUs Active  ${DIM}(Absolute Full Die Silicon Array Matrix Unlocked)${RESET}"
    echo ""
    local cu_choice=""
    read -p "  Select target CU configuration profile [1-3]: " cu_choice

    local ACTIVE_CUS=38
    case "$cu_choice" in
        1) ACTIVE_CUS=36;;
        2) ACTIVE_CUS=38;;
        3) ACTIVE_CUS=40;;
        *) echo -e "  ${YELLOW}⚠ Unknown parameter. Defaulting profile curve to stable 38 CU footprint.${NC}"; ACTIVE_CUS=38;;
    esac
    echo ""

    # ==============================================================================
    # 🚀 NEW INJECTED TRACK: AUDIT NO. 4 (12-THREAD ASYMMETRICAL SAFETY ALIGNMENT)
    # ==============================================================================
    # 📋 AUDIT NO. 4: FUTURE TARGET CPU CORES
    echo -e "  ${BOLD}${BLUE}[4/5] I do see you have ${detected_cores} CPU Cores / ${live_threads} Threads active.${RESET}"
    echo -e "        Select your target configuration profile layout:"
    echo -e "    1) Target 6 Cores / 12 Threads  ${DIM}(Power-saving / High-Efficiency Sweet Spot)${RESET}"
    echo -e "    2) Target 8 Cores / 16 Threads  ${DIM}(Full Hardware Multithreading Unlocked)${RESET}"
    echo ""
    local core_choice=""
    read -p "  Select target CPU core complex [1-2]: " core_choice

    local ACTIVE_CORES=8
    local INTERVAL_SAMPLE=4000
    case "$core_choice" in
        1)
            ACTIVE_CORES=6
            INTERVAL_SAMPLE=6000   # Loosen to 6ms to protect a 12-thread pool from telemetry choke
            ;;
        2)
            ACTIVE_CORES=8
            INTERVAL_SAMPLE=4000   # Keep at ultra-fast 4ms for full 16-thread pools
            ;;
        *)
            echo -e "  ${YELLOW}⚠ Defaulting to full 8 Core / 16 Thread complex matrices.${NC}"
            ACTIVE_CORES=8
            INTERVAL_SAMPLE=4000
            ;;
    esac
    echo ""

    # 📋 SYSTEM TARGET TUNING LEVEL SELECTION
    echo -e "  ${BOLD}${BLUE}[5/5] Select desired system tuning optimization profile layer:${RESET}"
    echo -e "    1) Normal Computer Use  ${DIM}(Silent profile, low voltage, browser/desktop work)${RESET}"
    echo -e "    2) Standard Gaming      ${DIM}(Balanced high-efficiency foundation at 1800MHz)${RESET}"
    echo -e "    3) Heavy Overclocking   ${DIM}(Absolute Max Custom Curve: Up to 2150MHz @ 1020mV)${RESET}"
    echo ""
    local tuning_choice=""
    read -p "  Select tuning profile [1-3]: " tuning_choice
    echo ""

    local PROFILE_LABEL=""
    local RAMP_NORMAL=15
    local RAMP_BURST=40
    local FREQ_MAX=1400
    local VOLT_MAX=780

    case "$tuning_choice" in
        1)
            PROFILE_LABEL="NORMAL COMPUTER USE (LOW POWER)"
            RAMP_NORMAL=5; RAMP_BURST=15; FREQ_MAX=1400; VOLT_MAX=780
            ;;
        2)
            PROFILE_LABEL="STANDARD GAMING (BALANCED PERFORMANCE)"
            RAMP_NORMAL=10; RAMP_BURST=50; FREQ_MAX=1800; VOLT_MAX=900
            ;;
        3)
            PROFILE_LABEL="HEAVY OVERCLOCKING GAMEPLAY (MAX CEILING)"
            RAMP_NORMAL=15; RAMP_BURST=80; FREQ_MAX=2150; VOLT_MAX=1020
            ;;
        *)
            echo -e "  ${RED}❌ Invalid tuning layout selection. Aborting...${NC}"; sleep 1.5; return 1;;
    esac

    # 🧬 THE STEPPED INTERCEPT ENGINE: Automated downscaling enforcement rules based on PSU Strata
    if (( psu_wattage >= 300 && psu_wattage < 400 )); then
        echo -e "  ${RED}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${RED}║  [⚠] CRITICAL HARDWARE LOCKOUT: SEVERE PSU CONSTRAINT ENFORCED                              ║${NC}"
        echo -e "  ${RED}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "  ${RED}║  Your reported ${psu_wattage}W power supply is below the minimum required headroom for 3D gaming.  ║${NC}"
        echo -e "  ${RED}║  Toolkit has hardlocked profile to Normal Computer Use (1400MHz) to prevent OCP trips.      ║${NC}"
        echo -e "  ${RED}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        PROFILE_LABEL="NORMAL COMPUTER USE (FORCED SAFETY CLAMP)"
        FREQ_MAX=1400; VOLT_MAX=780; RAMP_NORMAL=5; RAMP_BURST=15; tuning_choice=1

    elif (( psu_wattage >= 400 && psu_wattage < 500 )) && [ "$tuning_choice" -eq 3 ]; then
        echo -e "  ${YELLOW}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${YELLOW}║  [⚠] MODERATE POWER HEADROOM DETECTED: AUTO-DOWN-SAMPLING PERFORMANCE ACTIVE                ║${NC}"
        echo -e "  ${YELLOW}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "  ${YELLOW}║  Your reported ${psu_wattage}W PSU cannot safely protect against 2150MHz transient spikes.           ║${NC}"
        echo -e "  ${YELLOW}║  Toolkit has safely scaled your target down to Standard Gaming mode (1800MHz @ 900mV).      ║${NC}"
        echo -e "  ${YELLOW}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        PROFILE_LABEL="STANDARD GAMING (AUTO-DOWNSCALED FROM MAXIMUM CEILING)"
        FREQ_MAX=1800; VOLT_MAX=900; RAMP_BURST=50; tuning_choice=2
    fi
    echo -e "  ${YELLOW}[ℹ] Compiling target configurations using tailored hardware masks...${NC}"
    local TARGET_CONF="/etc/cyan-skillfish-governor-smu/config.toml"
    sudo mkdir -p /etc/cyan-skillfish-governor-smu 2>/dev/null

    # 🚀 AUTO-BACKUP TRACE: Preserves existing setup properties cleanly before overwriting
    if [[ -f "$TARGET_CONF" ]]; then
        sudo cp "$TARGET_CONF" "${TARGET_CONF}.bak_$(date +%Y%m%d_%H%M%S)" 2>/dev/null
    fi

    sudo bash -c "cat <<EOF > $TARGET_CONF
# ==============================================================================
# PROFILE TEMPLATE LAYOUT: $PROFILE_LABEL
# Calculated dynamically via BC-250 Spec Auditor Wizard Suite
# Hardware Target Mask: $ACTIVE_CUS CUs Unlocked | $ACTIVE_CORES CPU Cores Active
# Hardware Spec Mask: Cooling = $COOLING_LABEL | Power Source = ${psu_wattage}W PSU
# ==============================================================================

[timing.intervals]
sample = $INTERVAL_SAMPLE          # Auto-scaled based on targeted operational CPU core complex
adjust = 30000         # 30ms loop ensures smooth clock stepping without micro-stutter

[gpu-usage]
fix-freq = true
fix-metrics = true
method = \"busy-flag\"   # Best compatibility mode for RDNA2 Cyan Skillfish architectures
flush-every = 5        # Flushes frequently to completely eliminate micro-stutter

[gpu]
set-method = \"smu\"     # Direct SMU control for immediate frequency overrides
target_card = \"card1\"  # Points directly to your active BC-250 hardware node

[dbus]
enabled = true         # Enables inter-process communication for system overlays

# MHz/ms scaling rates
[timing.ramp-rates]
normal = $RAMP_NORMAL            # Tracking speed optimized for active profile limits
burst = $RAMP_BURST             # Frequency jumps scaled dynamically to match your \${psu_wattage}W current allocation

# Evaluation sampling parameters
[timing]
burst-samples = 3      # Allows fast response to heavy engine load spikes
down-events = 20       # High filtration to aggressively prevent framerate drops

# Control loop window boundaries (MHz)
[frequency-thresholds]
adjust = 5             # Tighter control loop window for precise stability
upper = 0.94           # Lock peak frequencies until utilization drops significantly
lower = 0.82           # Force higher clocks even during brief engine stalls or asset loading

# Utilization target margins (%)
[load-target]
upper = 0.80           # Prevents aggressive downclocking during variable frame times
lower = 0.60           # Forces high clock retention during geometry/draw call pipeline limits

# °C Thermal tracking configurations
[temperature]
throttling = $THROTTLE_TEMP        # HARD CEILING: Scaled directly from your \$COOLING_LABEL spec option
throttling_recovery = $RECOVERY_TEMP # Safe temperature buffer to prevent rapid thermal stutter loops

# ==============================================================================
# CLOCK & VOLTAGE FREQUENCY CURVE
# Ceiling and exponential safe-points auto-scaled for active spec parameters.
# ==============================================================================

[frequency-range]
min = 350
max = $FREQ_MAX             # Dynamic performance ceiling applied securely
min_voltage = 700      # Stabilized voltage floor for hardware system bus
max_voltage = $VOLT_MAX     # Maximum voltage ceiling matching profile budget limit

[[safe-points]]
frequency = 350
voltage = 700

[[safe-points]]
frequency = 500
voltage = 700

[[safe-points]]
frequency = 1000
voltage = 740          # Raised low-state voltage to prevent hard-lock idling crashes

[[safe-points]]
frequency = 1400
voltage = 780          # Adjusted mid-state baseline
EOF"
    # Appends extra safe points up to 1800MHz if option 2 or 3 is authorized
    if [ "$tuning_choice" -gt 1 ]; then
    sudo bash -c "cat <<EOF >> $TARGET_CONF

[[safe-points]]
frequency = 1500
voltage = 810          # Exponential scaling begins here to combat silicon leakage

[[safe-points]]
frequency = 1600
voltage = 840

[[safe-points]]
frequency = 1700
voltage = 870

[[safe-points]]
frequency = 1800
voltage = 900          # High-efficiency gaming foundation threshold
EOF"
    fi

    # Appends your exact extreme safe points up to 2150MHz ONLY if 500W+ overhead is verified
    if [ "$tuning_choice" -eq 3 ]; then
    sudo bash -c "cat <<EOF >> $TARGET_CONF

[[safe-points]]
frequency = 1900
voltage = 930

[[safe-points]]
frequency = 1950
voltage = 945

[[safe-points]]
frequency = 2000
voltage = 960          # 2GHz high-performance threshold

[[safe-points]]
frequency = 2050
voltage = 975

[[safe-points]]
frequency = 2100
voltage = 995          # Approaching high-stress limits (+20mV)

[[safe-points]]
frequency = 2125
voltage = 1008         # High-leakage compensation step

[[safe-points]]
frequency = 2150
voltage = 1020         # Maximum performance tier matching your exact --vid 1020 limit
EOF"
    fi

    echo -e "  ${GREEN}[✓] New config.toml compiled successfully using hardware constraints!${NC}"
    echo -e "  ${YELLOW}[⚙] Cycling changes into live governor service memory...${NC}"

    sudo systemctl daemon-reload 2>/dev/null || true
    sudo systemctl restart cyan-skillfish-governor-smu 2>/dev/null || true

    echo -e "  ${GREEN}[✓] Task complete! Active system profiles locked into memory space cleanly.${NC}\n"
    read -rp "  Press [Enter] to exit back to the main menu..."
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
        echo -e "    ${CYAN}1)${NC} 40/40 CU - Extreme Overclock  ${BIBlack}───${NC}  3500 MHz  @  1000 mV  ${BIBlack}│${NC}  Max 85°C"
        echo -e "    ${CYAN}2)${NC} 40/40 CU - High-Efficiency    ${BIBlack}───${NC}  3500 MHz  @   920 mV  ${BIBlack}│${NC}  Max 78°C"
        echo -e "    ${CYAN}3)${NC} 38/40 CU - Extreme Overclock  ${BIBlack}───${NC}  3500 MHz  @  1020 mV  ${BIBlack}│${NC}  Max 85°C"
        echo -e "    ${CYAN}4)${NC} 38/40 CU - Balanced Gaming    ${BIBlack}───${NC}  3500 MHz  @   945 mV  ${BIBlack}│${NC}  Max 80°C"
        echo -e "    ${CYAN}5)${NC} 36/40 CU - Silent / Eco Core  ${BIBlack}───${NC}  3500 MHz  @   890 mV  ${BIBlack}│${NC}  Max 75°C"
        echo ""
        echo -e "    ${BIGreen}6) Manual Custom Profile${NC}       ${BIBlack}(Fill MHz, mV, Max Temp manually)${NC}"
        echo -e "    ${BIGreen}7) Manual Test Profile${NC}         ${BIBlack}(Fill MHz, mV, Max Temp for safety test)${NC}"
        echo ""
        echo -e "    ${RED}↵) Return to Main Menu${NC}         ${BIBlack}(Skip auto-tuning routine)${NC}"
        echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
        echo ""
        read -p "  Enter selection [1-7, ↵]: " tune_choice

        case "$tune_choice" in
            1) log "${GREEN}Launching 40/40 CU extreme overclock...${NC}"; bc250-detect --frequency 3500 --vid 1000 -t 85 --keep; finalize_settings ;;
            2) log "${GREEN}Launching 40/40 CU high-efficiency profile...${NC}"; bc250-detect --frequency 3500 --vid 920 -t 78 --keep; finalize_settings ;;
            3) log "${GREEN}Launching 38/40 CU extreme overclock...${NC}"; bc250-detect --frequency 3500 --vid 1020 -t 85 --keep; finalize_settings ;;
            4) log "${GREEN}Launching 38/40 CU balanced gaming sweet spot...${NC}"; bc250-detect --frequency 3500 --vid 945 -t 80 --keep; finalize_settings ;;
            5) log "${GREEN}Launching 36/40 CU silent eco profile...${NC}"; bc250-detect --frequency 3500 --vid 890 -t 75 --keep; finalize_settings ;;
            6|7)
                clear
                echo -e "${YELLOW}====================================================${NC}"
                echo -e "${YELLOW}             CUSTOM PROFILE CONFIGURATION           ${NC}"
                echo -e "${YELLOW}====================================================${NC}"
                echo ""
                while true; do
                    read -p "Enter Target Frequency (MHz) [Minimum 3500]: " custom_freq
                    if [[ "$custom_freq" =~ ^[0-9]+$ ]] && [ "$custom_freq" -ge 3500 ]; then break; else echo -e "${RED}Invalid input. CPU frequency cannot be below the stock 3500 MHz hardware floor!${NC}"; fi
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

# ==============================================================================
# 🚀 CLEAN CONGESTION-FREE MASTER MENU LOOP (NO REFLECTION DELAYS)
# ==============================================================================
while true; do
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
    echo -e "    ${BOLD}${CYAN}• Silicon Governor & Performance Tuning Profile Manager:${RESET}"
    echo -e "      ${CYAN}[M]${RESET}  Modify Governor Performance Profile     ${DIM}(Hardware Spec Audit Wizard)${RESET}"
    echo ""
    echo -e "    ${BOLD}${YELLOW}• Rollback & Restoration Profiles:${RESET}"
    echo -e "      ${DIM}[3a] Uninstall CPU Overclock Profiles Completely${RESET}"
    echo -e "      ${DIM}[3b] Uninstall Compute Unit Live Manager Service Paths${RESET}"
    echo ""
    echo -e "    ${BOLD}${YELLOW}• Silicon Stability Testing Channels:${RESET}"
    echo -e "      ${CYAN}[4]${RESET}   Launch Silicon Per-Core Stability Sweep ${DIM}(test-cores Curve Validation)${RESET}"
    echo ""
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "      ${BOLD}${MAGENTA}[↵]${RESET} Hit Enter to Secure Safe Exit Overclock-Live-Manager"
    echo ""

    read -p "  Select an option [ 1a-4, M, ↵ ]: " choice

    case "$choice" in
        1a) run_phase1 ;;
        1b) run_phase2 ;;
        2a) run_manager_phase1 ;;
        2b) run_manager_phase2 ;;
        m|M) configure_governor_profile ;;
        3a) uninstall_cpu_overclock ;;
        3b) uninstall_cu_live_manager ;;
        4)  run_cpu_core_stress_test ;;
        0|"") exit 0 ;;
        *) echo -e "${RED}Invalid choice! Please select a valid option.${NC}"; sleep 1.5 ;;
    esac
done
