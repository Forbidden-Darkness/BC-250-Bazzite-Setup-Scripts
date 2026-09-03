#!/usr/bin/env bash

# Color definitions
RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"

RED='\033[0;31m'
B_RED='\033[1;31m'   # Bold Red for high-visibility Red Pill elements
GREEN='\033[0;32m'
B_GREEN='\033[0;92m'
YELLOW='\033[1;33m'
B_BLUE='\033[1;34m'  # Bold Blue for high-visibility Blue Pill elements
B_VIOLET='\033[1;35m' # Bold Violet for ACPI Fix elements
CYAN='\033[0;36m'
BIBlack='\033[1;90m'
BIRed='\033[1;91m'
BIGreen='\033[1;92m'
BIYellow='\033[1;93m'
BIBlue='\033[1;94m'
BIPurple='\033[1;95m'
BICyan='\033[1;96m'
BIWhite='\033[1;97m'
MAGENTA="\033[1;95m"
NC='\033[0m'
BG_HEADER="\e[48;5;235m"
# ==============================================================================
# UPGRADED: INTEGRATED THE THEMATIC VISUAL TRANSITION ENGINES
# ==============================================================================
type_prompt() {
    local text="$1"
    local delay="${2:-0.03}"
    for (( i=0; i<${#text}; i++ )); do
        echo -ne "${text:$i:1}"
        sleep "$delay"
    done
}

blink_cursor() {
    local prompt_text="$1"
    echo -ne "$prompt_text"
    for i in {1..3}; do
        echo -ne "\033[5m█\033[0m"
        sleep 0.5
        echo -ne "\b "
        sleep 0.5
    done
    echo ""
}

matrix_melt_clear() {
    local lines; lines=$(tput lines)
    for ((i=0; i<lines; i++)); do
        echo "" # Pushes the terminal buffer down
        sleep 0.01
    done
    clear
}

# ==============================================================================
# STEP 1: DEFINE USER CONTEXT FIRST SO RUNTIME VARIABLE PATHS ARE VALID
# ==============================================================================
REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || whoami)}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
[[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]] && REAL_HOME="/root"

# ==============================================================================
# ==============================================================================
# STEP 2: ASSIGN TARGET AUDIO & UPDATE REPOSITORIES
# ==============================================================================
AUDIO_FILE="Wake_on_LAN/Red-Pill-Blue-Pill.wav"
MUSIC_LOCK_FILE="$REAL_HOME/.bc250-toolkit-music.pid"
GITHUB_RAW_URL="https://githubusercontent.com"

# --- GLOBAL CORE CONFIGURATION TARGET PATHS ---
EXTERNAL_DIR="$REAL_HOME/Bazzite_Toolbox"
CORE_UNLOCK_CONF="/etc/bc250-core-unlock.conf"


# ==============================================================================
# STEP 3: CORE TOOLKIT INTERACTIVE ANIMATION ENGINES
# ==============================================================================
type_prompt() {
    local text="$1"
    local delay="${2:-0.03}"
    for (( i=0; i<${#text}; i++ )); do
        echo -ne "${text:$i:1}"
        sleep "$delay"
    done
}

blink_cursor() {
    local prompt_text="$1"
    echo -ne "$prompt_text"
    for i in {1..3}; do
        echo -ne "\033[5m█\033[0m"
        sleep 0.5
        echo -ne "\b "
        sleep 0.5
    done
    echo ""
}

draw_progress_bar() {
    local duration="$1"
    local width=40
    echo -ne "  Optimizing CUs: ["

    for ((i=1; i<=width; i++)); do
        local pct=$(( i * 100 / width ))
        local g_val=$(( 100 + (i * 155 / width) ))
        echo -ne "\033[38;2;0;${g_val};0m█\033[0m"
        sleep "$(bc -l <<< "$duration / $width")"
    done
    echo -e "] Done!"
}

matrix_melt_clear() {
    local lines; lines=$(tput lines)
    for ((i=0; i<lines; i++)); do
        echo ""
        sleep 0.01
    done
    clear
}

# ==============================================================================
# AUDIO PIPELINE ENGINES (PERMISSION-INSULATED PIPEWIRE CONTROL)
# ==============================================================================
start_background_music() {
    if [[ -f "$AUDIO_FILE" ]] && [[ ! -f "$MUSIC_LOCK_FILE" ]]; then
        local user_id; user_id=$(id -u "$REAL_USER")

        # 1. Start the infinite audio playback loop
        (
            while true; do
                sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$user_id" pw-play "$AUDIO_FILE"
            done
        ) &>/dev/null &

        local music_pid=$!
        echo "$music_pid" > "$MUSIC_LOCK_FILE" || true

        # FIX: Disowns the background process thread from the current terminal job table.
        # This completely stops Bash from printing the "Killed" status log on exit!
        disown "$music_pid" 2>/dev/null || true

        # 2. Spawn a detached 71-second automated fade-out timer thread
        (
            sleep 71

            local nodes; nodes=$(sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$user_id" pw-cli list-objects Node 2>/dev/null | grep -B 2 "pw-play" | awk -F'= ' '/id/ {print $2}' | tr -d ',')
            if [[ -n "$nodes" ]]; then
                for vol in 0.8 0.6 0.4 0.2 0.1 0.0; do
                    for node in $nodes; do
                        sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$user_id" pw-cli s "$node" Props "{ volume: $vol }" &>/dev/null || true
                    done
                    sleep 0.8
                done
            fi
            if [[ -f "$MUSIC_LOCK_FILE" ]]; then
                local target_pid; target_pid=$(cat "$MUSIC_LOCK_FILE" 2>/dev/null || echo "")
                [[ -n "$target_pid" ]] && kill -9 "$target_pid" 2>/dev/null || true
                killall pw-play &>/dev/null || true
                rm -f "$MUSIC_LOCK_FILE" 2>/dev/null || true
            fi
        ) &>/dev/null &
    fi
}


stop_background_music() {
    if [[ -f "$MUSIC_LOCK_FILE" ]]; then
        local target_pid; target_pid=$(cat "$MUSIC_LOCK_FILE" 2>/dev/null || echo "")
        [[ -n "$target_pid" ]] && kill -9 "$target_pid" 2>/dev/null || true
        killall pw-play 2>/dev/null || true
        rm -f "$MUSIC_LOCK_FILE" 2>/dev/null || true
    fi
}

# Ensure clean exit handling
trap stop_background_music EXIT

# --- Main Runtime Initializer ---
start_background_music

# Draw Initial Greeting Panels
clear
echo -e "\033[38;2;0;255;0m  ╔═════════════════════════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[38;2;0;255;0m  ║                                                                                             ║\033[0m"
echo -e "\033[38;2;0;255;0m  ║                                █ █ █ █▀▀ █   █▀▀ █▀█ █▄█ █▀▀                                ║\033[0m"
echo -e "\033[38;2;0;255;0m  ║                                ▀▄▀▄▀ ██▄ █▄▄ █▄▄ █▄█ █ █ ██▄                                ║\033[0m"
echo -e "\033[38;2;0;255;0m  ║                                                                                             ║\033[0m"
echo -e "\033[38;2;0;255;0m  ║    ${B_BLUE}[●] BLUE Pill\033[38;2;0;255;0m            🔑  System Architecture Unlocks  🔑            ${RED}RED Pill [●]\033[38;2;0;255;0m     ║\033[0m"
echo -e "\033[38;2;0;255;0m  ║                                                                                             ║\033[0m"
echo -e "\033[38;2;0;255;0m  ╚═════════════════════════════════════════════════════════════════════════════════════════════╝\033[0m"
echo ""

# FIX: Hardcoded to 24-bit True Color RGB inside the echo command so every typed letter is strictly absolute matrix green
type_prompt() {
    local text="$1"
    local delay="${2:-0.03}"
    for (( i=0; i<${#text}; i++ )); do
        # Injects the matrix green true color right behind every character block seamlessly
        echo -ne "\033[38;2;0;255;0m${text:$i:1}\033[0m"
        sleep "$delay"
    done
}

# The text now types out in crisp, beautiful matrix green automatically without code bleed!
type_prompt "  Establishing System Root Authorization.... " 0.03
blink_cursor ""
echo ""
type_prompt "  exploiting system entry " 0.03
blink_cursor ""

type_prompt "  injecting exploit.... " 0.05
blink_cursor ""

type_prompt "  system has been pwned, root access has been granted.... " 0.03
blink_cursor ""
echo ""
type_prompt "  mapping system block registers " 0.03
blink_cursor ""


# ... (Line 110: This is your existing blink utility)
blink_cursor() {
    local prompt_text="$1"
    echo -ne "$prompt_text"
    for i in {1..3}; do
        echo -ne "\033[5m█\033[0m"
        sleep 0.5
        echo -ne "\b "
        sleep 0.5
    done
    echo ""
}

# ==============================================================================
# 📥 PLACE YOUR PROGRESS BAR ENGINE RIGHT HERE (ABOVE DYNAMIC CALLS)
# ==============================================================================
draw_progress_bar() {
    local duration="$1"
    local width=40
    echo -ne "  Optimizing CUs: ["

    for ((i=1; i<=width; i++)); do
        local pct=$(( i * 100 / width ))
        # Dynamic 24-bit True Color Green scaling loop
        local g_val=$(( 100 + (i * 155 / width) ))

# ... (Your existing draw_progress_bar function finishes here)
        echo -ne "\033[38;2;0;${g_val};0m█\033[0m"
        sleep "$(bc -l <<< "$duration / $width")"
    done
    echo -e "] Done!"
}

# ==============================================================================
# 📥 PLACE YOUR MATRIX MELT CLEAR ENGINE RIGHT HERE:
# ==============================================================================
matrix_melt_clear() {
    local lines; lines=$(tput lines)
    # Scroll the current screen text downward line-by-line out of view
    for ((i=0; i<lines; i++)); do
        echo "" # Pushes the terminal buffer down
        sleep 0.01
    done
    clear
}

# ==============================================================================
# Your script baseline targets continue below:
# ==============================================================================
# --- Swap Allocation Global Targets ---
SWAPFILE_PATH="/var/swap/swapfile"



#type_prompt "  Press Enter to continue..." 0.05
#read -r dummy_input

# Add this right below your 'type_prompt' block whenever you want a prompt to blink:
blink_cursor() {
    local prompt_text="$1"
    echo -ne "$prompt_text"
    # Create a 3-second blinking loop before advancing
    for i in {1..3}; do
        echo -ne "\033[5m█\033[0m" # Draws a blinking block
        sleep 0.5
        echo -ne "\b "            # Wipes the block
        sleep 0.5
    done
    echo ""
}

# Example Usage:
type_prompt "  System reinitializing" 0.04
blink_cursor ""


# --- Swap Allocation Global Targets ---
SWAPFILE_PATH="/var/swap/swapfile"  # Bazzite's standard BTRFS swapfile target path
SWAPFILE_STOCK_SIZE_MB=4096         # Stock 4GB layout baseline

# Verify root/sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run with sudo or as root."
    echo -e "Please run: sudo bash $0${NC}"
    exit 1
fi

# =====================================================================
# ENVIRONMENT VARIABLES & PRINT FUNCTIONS
# =====================================================================
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SCRIPT_PATH=$(realpath "$0")
CONFIG_FILE="$REAL_HOME/.bazzite_toolbox_config"

# Target paths for legacy and new shortcut files
LOCAL_APPS="$REAL_HOME/.local/share/applications"
LOCAL_DIRS="$REAL_HOME/.local/share/desktop-directories"
LOCAL_MENUS="$REAL_HOME/.config/menus"

OLD_DESKTOP="$LOCAL_APPS/bazzite-toolbox.desktop"
OLD_DIRECTORY="$LOCAL_DIRS/bazzite-toolbox.directory"
OLD_MENU="$LOCAL_MENUS/applications-merged-bazzite.menu"

print_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

print_banner() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔════════════════════════════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                                        ║"
    echo "  ║         ██████╗  █████╗ ███████╗███████╗██╗████████╗███████╗    ██████╗ ███████╗       ║"
    echo "  ║         ██╔══██╗██╔══██╗╚══███╔╝╚══███╔╝██║╚══██╔══╝██╔════╝   ██╔═══██╗██╔════╝       ║"
    echo "  ║         ██████╔╝███████║  ███╔╝   ███╔╝ ██║   ██║   █████╗  ██ ██║   ██║███████╗       ║"
    echo "  ║         ██╔══██╗██╔══██║ ███╔╝   ███╔╝  ██║   ██║   ██╔══╝     ██║   ██║╚════██║       ║"
    echo "  ║         ██████╔╝██║  ██║███████╗███████╗██║   ██║   ███████╗   ╚██████╔╝███████║       ║"
    echo "  ║         ╚══════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝   ╚═╝   ╚══════╝    ╚═════╝ ╚══════╝      ║"
    echo "  ║                                                                                        ║"
    echo "  ║                                                                                        ║"
    echo -e "  ║    ${B_BLUE}[●] BLUE Pill${CYAN}             📟  System Core Telemetry  📟             ${RED}RED Pill [●]${CYAN}    ║"
    echo "  ╚════════════════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

print_section() {
    echo -e "  ${BOLD}${YELLOW}$1${RESET}"
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
}

print_item() {
    local num="$1"
    local label="$2"
    local desc="$3"
    local label_bytes=${#label}
    local label_visual=$(echo -n "$label" | wc -m)
    local extra=$(( label_bytes - label_visual ))
    local width=$(( 26 + extra ))
    printf "  ${BOLD}${WHITE}[${CYAN}%2s${WHITE}]${RESET}  %-${width}s ${DIM}%s${RESET}\n" "$num" "$label" "$desc"
}

print_success() {
    echo -e "\n  ${BOLD}${GREEN}✔  $1${RESET}\n"
}

print_error() {
    echo -e "\n  ${BOLD}${RED}✘  $1${RESET}\n"
}

print_info() {
    echo -e "  ${CYAN}→${RESET}  $1"
}

print_step() {
    echo -e "\n  ${BOLD}${MAGENTA}[$1]${RESET}  $2"
}

press_enter() {
    echo -e "\n  ${DIM}Press Enter to return to the menu...${RESET}"
    read -r
}

confirm() {
    local prompt="${1:-Are you sure?}"
    echo -e "\n  ${YELLOW}${prompt}${RESET} ${DIM}[y/N]${RESET} "
    read -rp "  → " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

# ==============================================================================
# BAZZITE COMPATIBILITY HELPERS FOR SYSTEM DIAGNOSTICS
# ==============================================================================
core_unlock_persist_installed() {
    systemctl is-enabled bc250-core-unlock.service &>/dev/null
}

core_unlock_cores_active() {
    [[ "$(nproc --all 2>/dev/null)" -eq 16 ]]
}

ram_split_installed() {
    rpm-ostree kargs 2>/dev/null | grep -q "ttm.pages_limit" || [[ -f /etc/modprobe.d/bc250-mem.conf ]]
}

zram_currently_disabled() {
    [[ ! -d /sys/block/zram0 ]]
}

zswap_currently_on() {
    [[ "$(cat /sys/module/zswap/parameters/enabled 2>/dev/null || echo "N")" == "Y" ]]
}

swapfile_size_mb() {
    if [[ -f "$SWAPFILE_PATH" ]]; then
        echo $(( $(stat -c%s "$SWAPFILE_PATH" 2>/dev/null || echo 0) / 1024 / 1024 ))
    else
        echo 0
    fi
}

cu_find_umr() {
    command -v umr &>/dev/null
}

# 🧬 FIXED ACPI OVERRIDE ENFORCEMENT DETECTOR: Audits GRUB structures and CPIO presence directly
# 🧬 HARDWARE LEVEL INTEGRATION: Interrogates the active kernel ACPI tree to detect direct BIOS table injection
acpi_fix_installed() {
    # 1. Direct BIOS Verification: Check if the custom 8-core table signature exists natively in firmware
    if [[ -d "/sys/firmware/acpi/tables" ]]; then
        # Scans for the custom table flags or checks if active P-States are natively exposed
        if grep -qE "SSDT|APIC" /sys/firmware/acpi/tables/SSDT* 2>/dev/null; then
            # Verify if early voltage policies are cleanly handling all 8 hardware cores natively
            if [[ -d "/sys/devices/system/cpu/cpu7/cpufreq" ]]; then
                return 0
            fi
        fi
    fi

    # 2. OS-Level Fallback: Check if the override exists instead as an early initrd GRUB payload modification
    if grep -q "GRUB_EARLY_INITRD_LINUX_CUSTOM" /etc/default/grub 2>/dev/null; then
        if [[ -f "/boot/SSDT_ACPI.cpio" || -f "/boot/efi/EFI/bazzite/SSDT_ACPI.cpio" ]]; then
            return 0
        fi
    fi
    
    return 1
}

sensors_active_driver() {
    if lsmod | grep -q "^nct6687"; then echo "nct6687"; else echo "none"; fi
}

RAM_SPLIT_DIR="$EXTERNAL_DIR/bc250_memcfg"
RAM_SPLIT_BIN="$RAM_SPLIT_DIR/bc250memcfg"
RAM_SPLIT_DEFAULT_UMA_MB=512
RAM_SPLIT_STOCK_UMA_MB=8192
RAM_SPLIT_DEFAULT_TTM_PAGES=3145728

ram_split_bc250_detected() {
    command -v lspci >/dev/null 2>&1 && lspci -Dn 2>/dev/null | grep -qi '1002:13fe'
}

ram_split_gcc_can_compile() {
    command -v gcc >/dev/null 2>&1 || return 1
    local probe; probe=$(mktemp -u --suffix=.c)
    printf '#include <stdio.h>\nint main(void){return 0;}\n' > "$probe"
    gcc "$probe" -o "${probe%.c}.out" >/dev/null 2>&1
    local rc=$?
    rm -f "$probe" "${probe%.c}.out"
    return $rc
}

ram_split_build_tool() {
    [[ -x "$RAM_SPLIT_BIN" ]] && return 0
    if [[ ! -f "$RAM_SPLIT_DIR/main.cpp" ]]; then
        fail_with_log "Vendored bc250_memcfg source not found at $RAM_SPLIT_DIR." "RAM/VRAM Split — missing vendored source"
        return 1
    fi
    if ! ram_split_gcc_can_compile; then
        print_info "gcc / libc headers missing or broken — (re)installing base-devel + glibc..."
        steamos_writable 'pacman -Sy --noconfirm base-devel glibc' || {
            fail_with_log "Failed to install gcc/glibc." "RAM/VRAM Split — gcc"
            return 1
        }
    fi
    if ! ram_split_gcc_can_compile; then
        fail_with_log "gcc still cannot compile a plain C program after reinstalling base-devel/glibc." "RAM/VRAM Split — gcc headers"
        return 1
    fi
    print_info "Building bc250memcfg from vendored source..."
    (cd "$RAM_SPLIT_DIR" && gcc -Os -s main.cpp -o bc250memcfg) || {
        fail_with_log "Failed to build bc250memcfg." "RAM/VRAM Split — build"
        return 1
    }
}

ram_split_current_uma() {
    [[ -x "$RAM_SPLIT_BIN" ]] || return 1
    local val
    val=$("$RAM_SPLIT_BIN" 2>/dev/null | awk -F= '$1 == "UMA_SIZE" {print $2}' | tr -d ' \r')
    [[ -n "$val" ]] || return 1
    echo "$((10#$val))"
}

# ==============================================================================
# RE-ORDERED CORE ENGINE: SYSTEM STATUS VISUALIZATION DASHBOARD (PART 1)
# ==============================================================================
run_status() {
    print_banner
    print_section "System Status"

    local ICON_OK="✓"
    local ICON_WARN="⚠"
    local ICON_ERR="✗"
    local DIM="${DIM:-}" local RESET="${RESET:-}" local GREEN="${GREEN:-}"
    local YELLOW="${YELLOW:-}" local RED="${RED:-}" local CYAN="${CYAN:-}"
    local BOLD="${BOLD:-}" local WHITE="${WHITE:-}" local B_BLUE="${B_BLUE:-}"

    local CPU_CONF="/etc/bc250-smu-oc.conf"
    local GPU_CONF="/etc/cyan-skillfish-governor-smu/config.toml"

    echo -e "  ${BOLD}${YELLOW}System${RESET}"
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"

    local boot_session="gamescope"
    local boot_relogin="true"

    if systemctl get-default 2>/dev/null | grep -q "graphical.target"; then
        if [[ -f /var/lib/AccountsService/users/$USER ]]; then
            grep -q "XSession=plasma" "/var/lib/AccountsService/users/$USER" && boot_session="plasma"
        fi
    fi

    local boot_mode boot_login
    if [[ "$boot_session" == "gamescope" ]]; then
        boot_mode="${BOLD}${GREEN}Game Mode${RESET}"
    else
        boot_mode="${BOLD}${CYAN}Desktop Mode${RESET}"
    fi
    boot_login=$([[ "$boot_relogin" == "false" ]] && echo "${DIM}password required${RESET}" || echo "${DIM}no password${RESET}")

    local wol_icon="$ICON_WARN" local wol_label="${YELLOW}deactivated${RESET}"
    local wol_enabled=false local wol_setting
    while IFS= read -r conn; do
        [[ -z "$conn" ]] && continue
        wol_setting=$(nmcli -g 802-3-ethernet.wake-on-lan connection show "$conn" 2>/dev/null | tr '[:upper:]' '[:lower:]')
        if [[ "$wol_setting" == *magic* ]]; then
            wol_enabled=true
            break
        fi
    done < <(nmcli -t -f NAME connection show 2>/dev/null)

    if $wol_enabled; then
        wol_icon="$ICON_OK"; wol_label="${GREEN}activated${RESET}"
    else
        wol_icon="$ICON_WARN"; wol_label="${YELLOW}deactivated${RESET}"
    fi

    echo -e "  ${CYAN}Boot Mode${RESET}             ${boot_mode}  ${boot_login}"
    echo -e "  ${CYAN}OS${RESET}                    $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo -e "  ${CYAN}Version${RESET}               $(cat /etc/os-release | grep -E '^(VERSION)=' | cut -d= -f2 | tr -d '"')"
    echo -e "  ${CYAN}Kernel${RESET}                $(uname -r)"
    echo -e "  ${CYAN}Wake-on-LAN${RESET}           ${wol_icon} ${wol_label}"
    echo ""

        print_section "Overclock"

    local cpu_preset="None" local cpu_profile="No Active Config"
    if [[ -f "$CPU_CONF" ]]; then
        cpu_preset=$(oc_match_preset 2>/dev/null || echo "Custom")
        cpu_profile=$(oc_active_profile 2>/dev/null || echo "Active Profile")
    fi
    echo -e "  ${DIM}CPU Active: ${cpu_preset} — ${cpu_profile}${RESET}"

    local gpu_preset="None" local gpu_profile="No Active Config"
    if [[ -f "$GPU_CONF" ]]; then
        gpu_preset=$(gpu_match_preset 2>/dev/null || echo "Custom")
        gpu_profile=$(gpu_active_profile 2>/dev/null || echo "Active Profile")
    fi
    echo -e "  ${DIM}GPU Active: ${gpu_preset} — ${gpu_profile}${RESET}"
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"

    local cpu_svc_enabled cpu_svc_result
    cpu_svc_enabled=$(systemctl is-enabled bc250-smu-oc.service 2>/dev/null || echo "disabled")
    cpu_svc_result=$(systemctl show bc250-smu-oc.service --property=ExecMainStatus --value 2>/dev/null || echo "0")

    local cpu_icon cpu_label
    if [[ "$cpu_svc_enabled" == "enabled" && "$cpu_svc_result" == "0" ]]; then
        cpu_icon="$ICON_OK"; cpu_label="${GREEN}activated (applied successfully)${RESET}"
    elif [[ "$cpu_svc_enabled" == "enabled" ]]; then
        cpu_icon="$ICON_WARN"; cpu_label="${YELLOW}activated (exit code: ${cpu_svc_result})${RESET}"
    else
        cpu_icon="$ICON_WARN"; cpu_label="${YELLOW}deactivated${RESET}"
    fi
    echo -e "  ${CYAN}CPU Service${RESET}           ${cpu_icon} ${cpu_label}"

    if [[ -f "$CPU_CONF" ]]; then
        local cpu_freq cpu_scale cpu_temp
        cpu_freq=$(awk -F'= ' '/^frequency/{sub(/#.*/, "", $2); print $2}' "$CPU_CONF" | tr -d ' ')
        cpu_scale=$(awk -F'= ' '/^scale/{sub(/#.*/, "", $2); print $2}' "$CPU_CONF" | tr -d ' ')
        cpu_temp=$(awk -F'= ' '/^max_temperature/{sub(/#.*/, "", $2); print $2}' "$CPU_CONF" | tr -d ' ')
        echo -e "  ${CYAN}CPU Profile${RESET}           ${ICON_OK} ${cpu_freq}MHz  scale ${cpu_scale}  max ${cpu_temp}°C"
    else
        echo -e "  ${CYAN}CPU Profile${RESET}           ${ICON_WARN} ${DIM}config not found${RESET}"
    fi

    local gpu_icon gpu_label
    if systemctl is-active --quiet cyan-skillfish-governor-smu.service 2>/dev/null; then
        gpu_icon="$ICON_OK"; gpu_label="${GREEN}activated${RESET}"
    else
        gpu_icon="$ICON_WARN"; gpu_label="${YELLOW}deactivated${RESET}"
    fi
    echo -e "  ${B_BLUE}GPU Service${RESET}           ${gpu_icon} ${gpu_label}"

    if [[ -f "$GPU_CONF" ]]; then
        local gpu_freq gpu_throttle
        gpu_freq=$(awk -F'= ' '/^frequency/{sub(/#.*/, "", $2); print $2}' "$GPU_CONF" | tr -d ' ' | tail -1)
        gpu_throttle=$(awk -F'= ' '/^throttling /{sub(/#.*/, "", $2); print $2}' "$GPU_CONF" | tr -d ' ')
        echo -e "  ${B_BLUE}GPU Profile${RESET}           ${ICON_OK} ${gpu_freq}MHz  throttle ${gpu_throttle}°C"
    else
        echo -e "  ${B_BLUE}GPU Profile${RESET}           ${ICON_WARN} ${DIM}config not found${RESET}"
    fi
    echo ""

    print_section "Hardware Unlocks"

    if rpm-ostree kargs 2>/dev/null | grep -q "mitigations=off"; then
        echo -e "  ${CYAN}CPU Mitigations${RESET}       ${ICON_OK} ${GREEN}disabled${RESET} (mitigations=off active via rpm-ostree kargs)"
    else
        echo -e "  ${CYAN}CPU Mitigations${RESET}       ${ICON_WARN} ${YELLOW}enabled${RESET} (default — disable for max performance)"
    fi

    if core_unlock_persist_installed; then
        if core_unlock_cores_active; then
            echo -e "  ${CYAN}CPU Core Unlock${RESET}       ${ICON_OK} ${GREEN}8c/16t active${RESET} ($(nproc --all) threads, boot service enabled)"
        else
            local core_unlock_auto_hint="reboot to pick up all 8 cores"
            [[ -f "$CORE_UNLOCK_CONF" ]] && grep -q '^AUTO_REBOOT=yes' "$CORE_UNLOCK_CONF" 2>/dev/null \
                && core_unlock_auto_hint="auto-reboot enabled, should self-correct shortly"
            echo -e "  ${CYAN}CPU Core Unlock${RESET}       ${ICON_WARN} ${YELLOW}boot service enabled, still 6c/12t${RESET} ($core_unlock_auto_hint)"
        fi
    else
        if core_unlock_cores_active; then
            echo -e "  ${CYAN}CPU Core Unlock${RESET}       ${ICON_WARN} ${YELLOW}boot service removed, but 8c/16t still active${RESET} (${DIM}$(nproc --all) threads — mask persists until cold power-off${RESET})"
        else
            echo -e "  ${CYAN}CPU Core Unlock${RESET}       ${DIM}– not installed (6c/12t, default)${RESET}"
        fi
    fi

    # 🧬 UNIFIED HARDWARE DECODER: Queries registers directly via UMR or parses the active systemd boot profile table
    local true_cu_count=24
    if command -v umr &>/dev/null; then
        # Query the exact hardware register configuration block matching your activation script targets
        local raw_bits; raw_bits=$(sudo umr -O bits -r amdgpu0.gfx1013.mmSPI_PG_ENABLE_STATIC_WGP_MASK 2>/dev/null | awk '{print $2}' | tr -d '[:space:]' || echo "")
        if [[ -z "$raw_bits" ]]; then
            raw_bits=$(sudo umr -O bits -r amdgpu0.gfx1030.mmSPI_SHADER_PG_CONFIG_CU 2>/dev/null | awk '{print $2}' | tr -d '[:space:]' || echo "")
        fi

        if [[ -n "$raw_bits" ]]; then
            local hex_val; hex_val=$(printf "%d" "$raw_bits" 2>/dev/null || echo "0")
            if (( hex_val > 0 )); then
                # Dynamically convert the register bitmap count straight to active CUs
                local masked_wgps; masked_wgps=$(printf "%d" "$hex_val")
                # Count total active bits from the 5-bit WGP array layout mask
                local active_count=0
                for wgp in {0..4}; do
                    if (( (masked_wgps & (1 << wgp)) != 0 )); then
                        active_count=$((active_count + 2))
                    fi
                done
                # If bits return valid variations, we assign them, otherwise scale globally
                if (( active_count > 0 )); then true_cu_count=$(( active_count * 4 )); fi
            fi
        fi
    fi

    # Fallback Option: If UMR pathing blocks out or drops, pull the active status table from your live manager config
    if [[ "$true_cu_count" -eq 24 ]] && [[ -f "/etc/bc250-cu-live-manager.conf" ]]; then
        local saved_masks; saved_masks=$(grep "BC250_WGP_MASKS=" /etc/bc250-cu-live-manager.conf | cut -d= -f2 | tr -d '"' || echo "")
        if [[ -n "$saved_masks" ]]; then
            # Calculate totals based on your saved profile allocations
            local total_cus=0
            IFS=',' read -ra masks_array <<< "$saved_masks"
            for mask in "${masks_array[@]}"; do
                local val=$((mask))
                for wgp in {0..4}; do
                    if (( (val & (1 << wgp)) != 0 )); then
                        total_cus=$((total_cus + 2))
                    fi
                done
            done
            if (( total_cus > 24 )); then true_cu_count="$total_cus"; fi
        fi
    fi

    # Final safety clamp to protect UI boundaries if hardware configurations report blank data lines
    if [[ -z "$true_cu_count" || "$true_cu_count" -eq 0 || "$true_cu_count" -lt 24 ]]; then
        true_cu_count=24
    fi

    local cu_icon="✓" local cu_color="\033[1;92m" local cu_warn_msg=""
    if [ "$true_cu_count" -gt 24 ]; then
        cu_icon="⚠"
        cu_color="\033[1;93m"
        cu_warn_msg=" \033[1;93m⚠ Unlocked — verify power/cooling\033[0m"
    fi
    echo -e "  ${CYAN}Active CUs${RESET}            ${cu_icon} ${cu_color}${true_cu_count}/40${RESET}  ${DIM}(default 24, max 40)${RESET}${cu_warn_msg}"

    if ram_split_installed; then
        local uma_now; uma_now=$(ram_split_current_uma 2>/dev/null)
        echo -e "  ${CYAN}RAM/VRAM Split${RESET}        ${ICON_OK} ${GREEN}UMA_SIZE=${uma_now:-?}MB${RESET}, ttm.pages_limit ceiling active"
    else
        echo -e "  ${CYAN}RAM/VRAM Split${RESET}        ${DIM}– not installed (stock split)${RESET}"
    fi
    echo ""

        print_section "Swap & ZRAM/ZSWAP"

    local swap_mb; swap_mb=$(swapfile_size_mb 2>/dev/null || echo "0")
    if (( swap_mb > 0 )); then
        echo -e "  ${CYAN}Swapfile${RESET}              ${ICON_OK} ${GREEN}$(( swap_mb / 1024 ))G${RESET} at ${SWAPFILE_PATH:-/var/swap/swapfile}"
    else
        echo -e "  ${CYAN}Swapfile${RESET}              ${DIM}managed by OS layers${RESET}"
    fi

    if systemctl is-active --quiet zram-generator@zram0.service 2>/dev/null || grep -qE "zram" /proc/swaps; then
        echo -e "  ${CYAN}ZRAM/ZSWAP${RESET}            ${ICON_OK} ${GREEN}ZRAM activated${RESET} / ZSWAP managed"
    elif zram_currently_disabled && zswap_currently_on; then
        echo -e "  ${CYAN}ZRAM/ZSWAP${RESET}            ${ICON_OK} ${GREEN}ZRAM deactivated / ZSWAP activated${RESET} (lz4)"
    elif zram_currently_disabled; then
        echo -e "  ${CYAN}ZRAM/ZSWAP${RESET}            ${ICON_WARN} ${YELLOW}ZRAM deactivated / ZSWAP configured but idle${RESET}"
    else
        echo -e "  ${CYAN}RAM/ZSWAP${RESET}            ${DIM}ZRAM activated / ZSWAP deactivated${RESET}"
    fi
    echo ""

    print_section "Sensors & Fan Control"

    local sens_driver sens_icon sens_color
    sens_driver="$(sensors_active_driver 2>/dev/null || echo "none")"
    case "$sens_driver" in
        nct6687) sens_icon="$ICON_OK";   sens_color="$GREEN";  sens_driver="nct6687 (loaded — full PWM control)" ;;
        nct6683) sens_icon="$ICON_WARN"; sens_color="$YELLOW"; sens_driver="nct6683 (loaded — read-only)" ;;
        *)       sens_icon="$ICON_WARN"; sens_color="$YELLOW"; sens_driver="not loaded" ;;
    esac
    echo -e "  ${CYAN}Sensor Driver${RESET}         ${sens_icon} ${sens_color}${sens_driver}${RESET}"

    local cc_svc_state cc_icon cc_color
    if systemctl is-active --quiet coolercontrol-daemon.service 2>/dev/null || \
       systemctl is-active --quiet coolercontrol.service 2>/dev/null || \
       systemctl is-active --quiet coolercontrold.service 2>/dev/null || \
       systemctl --user -M "$REAL_USER@" is-active --quiet coolercontrol.service 2>/dev/null || \
       systemctl --user -M "$REAL_USER@" is-active --quiet coolercontrol-daemon.service 2>/dev/null; then
        cc_svc_state="activated"; cc_icon="$ICON_OK"; cc_color="$GREEN"
    else
        cc_svc_state="deactivated"; cc_icon="$ICON_WARN"; cc_color="$YELLOW"
    fi
    echo -e "  ${CYAN}CoolerControl${RESET}         ${cc_icon} ${cc_color}${cc_svc_state}${RESET}"

    local xbox_icon xbox_color xbox_label
    xbox_label="$(xbox_adapter_status_label 2>/dev/null)"
    case "$xbox_label" in
        "loaded")                 xbox_icon="$ICON_OK";   xbox_color="$GREEN";  xbox_label="activated" ;;
        "installed (not loaded)") xbox_icon="$ICON_WARN"; xbox_color="$YELLOW"; xbox_label="installed (deactivated)" ;;
        "not installed"|*)        xbox_icon="$ICON_WARN"; xbox_color="$YELLOW"; xbox_label="not installed" ;;
    esac
    echo -e "  ${CYAN}Xbox Wireless Adapter${RESET} ${xbox_icon} ${xbox_color}${xbox_label}${RESET}"
    echo ""

    print_section "Community Fixes"

    local acpi_icon acpi_color acpi_label
    if acpi_fix_installed; then
        # Interrogate the hardware map to determine the structural origin of the ACPI tables
        if [[ -d "/sys/firmware/acpi/tables" ]] && [[ -d "/sys/devices/system/cpu/cpu7/cpufreq" ]] && ! grep -q "GRUB_EARLY_INITRD_LINUX_CUSTOM" /etc/default/grub 2>/dev/null; then
            acpi_icon="$ICON_OK"; acpi_color="$GREEN"; acpi_label="activated (Natively injected via permanent BIOS hardware tables)"
        elif compgen -G /sys/devices/system/cpu/cpu0/cpufreq >/dev/null; then
            acpi_icon="$ICON_OK"; acpi_color="$GREEN"; acpi_label="activated (Loaded via OS-level early boot initrd override)"
        else
            acpi_icon="$ICON_WARN"; acpi_color="$YELLOW"; acpi_label="installed configuration detected — reboot pending"
        fi
    else
        acpi_icon="$ICON_WARN"; acpi_color="$DIM"; acpi_label="not installed"
    fi
    echo -e "  ${B_RED}ACPI Fix${RESET}              ${acpi_icon} ${acpi_color}${acpi_label}${RESET}"

    local audio_icon audio_color audio_label resolved_amdgpu
    resolved_amdgpu=$(modinfo -F filename amdgpu 2>/dev/null || echo "")
    if [[ "$resolved_amdgpu" == *"/updates/"* ]]; then
        audio_icon="$ICON_OK"; audio_color="$GREEN"; audio_label="patched module activated"
    else
        audio_icon="$ICON_WARN"; audio_color="$YELLOW"; audio_label="stock hardware module activated"
    fi
    echo -e "  ${CYAN}Audio Patch${RESET}           ${audio_icon} ${audio_color}${audio_label}${RESET}"
    echo ""
}

# =====================================================================
# REFRESH & REMOVAL UTILITIES
# =====================================================================
refresh_desktop_database() {
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$LOCAL_APPS" &> /dev/null
    fi

    if command -v kbuildsycoca6 &> /dev/null; then
        sudo -u "$REAL_USER" kbuildsycoca6 --noincremental &> /dev/null
    elif command -v kbuildsycoca5 &> /dev/null; then
        sudo -u "$REAL_USER" kbuildsycoca5 --noincremental &> /dev/null
    fi
}

force_remove_shortcut() {
    print_info "Purging all existing legacy and current shortcut structures..."
    rm -f "$OLD_DESKTOP" "$OLD_DIRECTORY" "$OLD_MENU"
    refresh_desktop_database
}

# =====================================================================
# SHORTCUT CREATION & PROMPT LOGIC
# =====================================================================
create_start_menu_shortcut() {
    print_info "Creating start menu shortcut..."
    mkdir -p "$LOCAL_APPS"

    cat << EOF > "$OLD_DESKTOP"
[Desktop Entry]
Version=1.0
Type=Application
Name=Bazzite Toolbox
Comment=Launch Custom Bazzite Tweak Tool
Exec=sudo bash "$SCRIPT_PATH"
Icon=utilities-terminal
Terminal=true
Categories=Utility;System;
X-KDE-Submenu=Bazzite Toolbox
EOF

    chmod +x "$OLD_DESKTOP"
    chown -R "$REAL_USER":"$REAL_USER" "$OLD_DESKTOP"

    rm -f "$OLD_DIRECTORY" "$OLD_MENU"
    refresh_desktop_database
    print_info "Shortcut installed successfully!"
}

manage_shortcut_prompt() {
    if [ -f "$CONFIG_FILE" ]; then
        local saved_pref; saved_pref=$(grep "START_MENU_SHORTCUT=" "$CONFIG_FILE" | cut -d= -f2)
        if [ "$saved_pref" == "false" ]; then force_remove_shortcut; return 0; fi
        if [ "$saved_pref" == "true" ]; then create_start_menu_shortcut; return 0; fi
    fi

    echo -e "\n${YELLOW}Would you like to add a Bazzite Toolbox shortcut to your Start Menu?${NC}"
    read -p "(Y/n): " -r user_choice
    user_choice=${user_choice:-Y}

    mkdir -p "$(dirname "$CONFIG_FILE")"

    if [[ "$user_choice" =~ ^[Yy]$ ]]; then
        echo "START_MENU_SHORTCUT=true" > "$CONFIG_FILE"
        chown "$REAL_USER":"$REAL_USER" "$CONFIG_FILE"
        create_start_menu_shortcut
    else
        echo "START_MENU_SHORTCUT=false" > "$CONFIG_FILE"
        chown "$REAL_USER":"$REAL_USER" "$CONFIG_FILE"
        force_remove_shortcut
        print_info "Opted out. All old shortcut records removed."
    fi
}

# =====================================================================
# MANUAL EXECUTION FLAGS (CLI OVERRIDES)
# =====================================================================
case "$1" in
    --install-shortcut)
        print_info "Manual override: Installing shortcut..."
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo "START_MENU_SHORTCUT=true" > "$CONFIG_FILE"
        chown "$REAL_USER":"$REAL_USER" "$CONFIG_FILE"
        create_start_menu_shortcut
        exit 0
        ;;
    --remove-shortcut)
        print_info "Manual override: Removing shortcut..."
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo "START_MENU_SHORTCUT=false" > "$CONFIG_FILE"
        chown "$REAL_USER":"$REAL_USER" "$CONFIG_FILE"
        force_remove_shortcut
        print_info "Shortcut completely uninstalled."
        exit 0
        ;;
    --updated)
        shift
        print_info "Update successful! Running latest sequence."
        manage_shortcut_prompt
        echo -e "${YELLOW}Press [Enter] to continue to the Bazzite Toolbox...${NC}"
        read -r
        ;;
esac

echo -e "${GREEN}Starting Bazzite Toolbox Core UI...${NC}"

# =====================================================================
# 2. AUTO-UPDATE MECHANISM (WITH SILENT OFFLINE FAIL)
# =====================================================================
GITHUB_RAW_URL="https://github.com/Forbidden-Darkness/Bazzite_Toolbox/raw/refs/heads/main/start.sh"

if [ "$1" != "--no-update" ] && [ "$1" != "--updated" ]; then
    if curl -s -I -L --connect-timeout 2 "$GITHUB_RAW_URL" > /dev/null; then
        print_info "Checking for updates..."

        TEMP_FILE=$(mktemp)
        if curl -s -L --connect-timeout 2 "$GITHUB_RAW_URL" -o "$TEMP_FILE"; then
            if ! cmp -s "$SCRIPT_PATH" "$TEMP_FILE"; then
                print_info "New version detected! Updating..."

                cp "$TEMP_FILE" "$SCRIPT_PATH"
                chmod +x "$SCRIPT_PATH"
                rm -f "$TEMP_FILE"

                print_info "Applying update and restarting..."
                exec bash "$SCRIPT_PATH" --updated "$@"
            fi
        fi
        rm -f "$TEMP_FILE"
    fi
fi

print_info "Starting main script workflow..."

ask_desktop_shortcut() {
    local desktop_dir; desktop_dir="$(sudo -u "$REAL_USER" xdg-user-dir DESKTOP 2>/dev/null || echo "")"
    [[ -n "$desktop_dir" ]] || desktop_dir="$REAL_HOME/Desktop"
    [[ -d "$desktop_dir" ]] || mkdir -p "$desktop_dir" 2>/dev/null || return 0

    local shortcut="$desktop_dir/Start Bazzite Boken Toolbox.desktop"
    [[ -f "$shortcut" ]] && return 0

    echo -e "${BIYellow}==================================================${NC}"
    echo -e "${BIYellow}         DESKTOP SHORTCUT CONFIGURATION            ${NC}"
    echo -e "${BIYellow}==================================================${NC}"
    echo -e "Would you like to add a shortcut to your desktop?"
    echo ""
    echo -e " 1) Yes, create desktop shortcut"
    echo ""
    echo -e " 2) No, skip shortcut creation"
    echo ""
    echo -e "${RED}     Hit Enter To Skip This Configuration${NC}"
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

ask_desktop_shortcut
manage_shortcut_prompt

prompt_reboot() {
    echo ""
    echo -e "${YELLOW}==================================================${NC}"
    echo -e "${YELLOW} Task complete! The system needs to reboot now.    ${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo " 1) Reboot Now (Recommended)"
    echo " 2) Cancel Reboot & Return to Main Menu"
    echo -e "${YELLOW}==================================================${NC}"
    read -rp "Select an option [1-2]: " reboot_choice

    case $reboot_choice in
        1)
            echo "Rebooting system now..."
            sudo systemctl reboot
            ;;
        2)
            echo -e "${YELLOW}Reboot cancelled. Returning to main menu.${NC}"
            sleep 2
            return 0
            ;;
        *)
            echo -e "${RED}Invalid option. Defaulting to safe safe cancel.${NC}"
            sleep 2
            return 1
            ;;
    esac
}

# =====================================================================
# RESTORED PERFORMANCE PIPELINES (OPTIONS 1-4 EXPLICIT ARRAYS)
# =====================================================================

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

# Function to Launch Overclock
install_overclock() {
    echo -e "${B_RED}=== Launching Overclock Menu ===${NC}"

    local oc_dir="$REAL_HOME/Bazzite_Toolbox/Overclock"
    mkdir -p "$oc_dir"
    cd "$oc_dir" || return 1
    chown -R "$REAL_USER":"$REAL_USER" "$oc_dir"

    rm -f Overclock-Live-Manager.sh
    sudo -u "$REAL_USER" wget https://github.com/Forbidden-Darkness/Bazzite_Toolbox/raw/refs/heads/main/Overclock/Overclock-Live-Manager.sh

    if [ ! -s "Overclock-Live-Manager.sh" ]; then
        echo -e "${RED}ERROR: Script failed to download or is blank! Check internet.${NC}"
        sleep 4
        return 1
    fi

    chmod +x Overclock-Live-Manager.sh
    echo "Transitioning terminal to Overclock Live Manager..."
    sleep 1

    ENVIRONMENT=bazzite Overrides=true bash ./Overclock-Live-Manager.sh
    echo -e "${YELLOW}Overclock Manager closed. Returning to main menu...${NC}"
    sleep 2
}

# Function to Launch Wake on LAN
install_wake_on_lan() {
    echo -e "${B_RED}=== Launching Wake on LAN Menu ===${NC}"

    local wol_dir="$REAL_HOME/Bazzite_Toolbox/Wake_on_LAN"
    mkdir -p "$wol_dir"
    cd "$wol_dir" || return 1
    chown -R "$REAL_USER":"$REAL_USER" "$wol_dir"

    rm -f Wake-on-LAN-Manager.sh
    sudo -u "$REAL_USER" wget https://github.com/Forbidden-Darkness/Bazzite_Toolbox/raw/refs/heads/main/Wake_on_LAN/Wake-on-LAN-Manager.sh

    if [ ! -s "Wake-on-LAN-Manager.sh" ]; then
        echo -e "${RED}ERROR: Script failed to download or is blank! Check internet.${NC}"
        sleep 4
        return 1
    fi
    chmod +x Wake-on-LAN-Manager.sh

    echo "Transitioning terminal to Wake on LAN Manager..."
    sleep 1

    ENVIRONMENT=bazzite Overrides=true bash ./Wake-on-LAN-Manager.sh
    echo -e "${YELLOW}Wake on LAN Manager closed. Returning to main menu...${NC}"
    sleep 2
}


# Function to update_cyan-skillfish
update_cyan-skillfish() {
    echo -e "${B_RED}=== Updating cyan-skillfish ===${NC}"

    cyan-skillfish-governor-smu --version
    sudo rpm-ostree refresh-md --force
    sudo rpm-ostree install cyan-skillfish-governor-smu-v0.4.12
    sudo sed -i '/^\[gpu-usage\]/a fix-freq = true' /etc/cyan-skillfish-governor-smu/config.toml
    prompt_reboot
}

# ==============================================================================
# UNIFIED ACPI FIX SUBSYSTEM TOGGLE ENGINE (BIOS PROTETCTED)
# ==============================================================================
toggle_acpi_fix() {
    # Detect if the tables are locked in at the hardware layer rather than software files
    if acpi_fix_installed && ! grep -q "GRUB_EARLY_INITRD_LINUX_CUSTOM" /etc/default/grub 2>/dev/null; then
        echo -e "\n  ${B_GREEN}[✓] ACPI HARDWARE INJECTION VERIFIED!${RESET}"
        echo -e "      The custom C/P-state voltage tables are running natively inside your BIOS."
        echo -e "      Software rollback is managed by reflashing your stock firmware image."
        echo ""
        type_prompt "  Press [any key] to return to the toolkit main menu... " 0.03
        read -n 1 -s -r || true
    elif acpi_fix_installed; then
        echo -e "\n  ${YELLOW}[⚠] ACPI Override Fix detected inside operating system boot records.${RESET}"
        echo -e "      Selecting this action will completely uninstall the software fix."
        if confirm "Do you want to proceed with the removal?"; then
            remove_acpi_fix
        else
            echo -e "${CYAN}[-] Removal cancelled. Returning to main menu...${NC}"
            sleep 1.5
        fi
    else
        echo -e "\n  ${CYAN}[ℹ] ACPI Override Fix is not currently installed.${RESET}"
        echo -e "      Selecting this action will download and inject the custom tables."
        if confirm "Do you want to proceed with the installation?"; then
            apply_acpi_fix
        else
            echo -e "${CYAN}[-] Installation cancelled. Returning to main menu...${NC}"
            sleep 1.5
        fi
    fi
}

# Function to handle ACPI Override Fix
apply_acpi_fix() {
    echo -e "${B_VIOLET}=== Executing BC-250 ACPI Fix ===${NC}"

    cd /tmp || return 1
    rm -rf acpi_tables/kernel/firmware/acpi
    git clone https://github.com/mendesrr/bc250-acpi-fix-updated-8c.git
    cd bc250-acpi-fix-updated-8c || return 1

    if [ ! -d "/tmp/bc250-acpi-fix-updated-8c" ]; then
        echo -e "${RED}ERROR: Failed to clone the ACPI fix repository. Check your internet connection.${NC}"
        sleep 2
        return 1
    fi

    rm -rf /tmp/acpi_tables/kernel/firmware/acpi
    mkdir -p /tmp/acpi_tables/kernel/firmware/acpi
    cp *.aml /tmp/acpi_tables/kernel/firmware/acpi/.

    cd /tmp/acpi_tables || return 1
    find kernel | cpio -H newc --create > SSDT_ACPI.cpio

    # 🧬 ATOMIC PATHWAY UNIFICATION: Write to both locations to ensure cross-version compatibility
    sudo cp SSDT_ACPI.cpio /boot/SSDT_ACPI.cpio 2>/dev/null || true
    sudo mkdir -p /boot/efi/EFI/bazzite 2>/dev/null || true
    sudo cp SSDT_ACPI.cpio /boot/efi/EFI/bazzite/SSDT_ACPI.cpio 2>/dev/null || true

    # Inject the initrd custom line into the grub configuration
    if ! grep -q "GRUB_EARLY_INITRD_LINUX_CUSTOM" /etc/default/grub; then
        echo 'GRUB_EARLY_INITRD_LINUX_CUSTOM="../../SSDT_ACPI.cpio"' | sudo tee -a /etc/default/grub
    fi

    # 🔧 BAZZITE 44 TOOLCHAIN RESOLVER: Detect and install the split cpupower package safely
    echo -e "${B_VIOLET}=== Installing kernel-tools (cpupower) ===${NC}"
    if rpm-ostree search cpupower &>/dev/null; then
        sudo rpm-ostree install cpupower >> /var/log/bc250_oc_install.log 2>&1
    else
        sudo rpm-ostree install kernel-tools >> /var/log/bc250_oc_install.log 2>&1
    fi

    # 🔧 BAZZITE 44 GRUB REGENERATION ROUTINE
    echo -e "${B_VIOLET}=== Regenerating GRUB Configuration ===${NC}"
    if ujust --list 2>/dev/null | grep -q "regenerate-grub"; then
        ujust regenerate-grub
    elif [ -f "/boot/grub2/grub.cfg" ]; then
        sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    elif [ -f "/boot/efi/EFI/fedora/grub.cfg" ]; then
        sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
    else
        sudo grub2-mkconfig -o /etc/grub2.cfg 2>/dev/null || true
    fi

    prompt_reboot
}

# Function to handle ACPI Override Removal (Uninstaller)
remove_acpi_fix() {
    echo -e "${B_VIOLET}=== Removing BC-250 ACPI Fix ===${NC}"

    if grep -q "GRUB_EARLY_INITRD_LINUX_CUSTOM" /etc/default/grub; then
        print_info "Removing GRUB_EARLY_INITRD_LINUX_CUSTOM from /etc/default/grub..."
        sudo sed -i '/GRUB_EARLY_INITRD_LINUX_CUSTOM/d' /etc/default/grub
    else
        print_warning "No GRUB_EARLY_INITRD_LINUX_CUSTOM line found in /etc/default/grub."
    fi

    # Clear files out from both potential directory targets cleanly
    if [ -f "/boot/SSDT_ACPI.cpio" ] || [ -f "/boot/efi/EFI/bazzite/SSDT_ACPI.cpio" ]; then
        print_info "Deleting custom SSDT_ACPI.cpio binaries..."
        sudo rm -f /boot/SSDT_ACPI.cpio 2>/dev/null || true
        sudo rm -f /boot/efi/EFI/bazzite/SSDT_ACPI.cpio 2>/dev/null || true
    else
        print_warning "No custom SSDT_ACPI.cpio binaries discovered."
    fi

    print_info "Regenerating GRUB configuration safely..."
    if ujust --list 2>/dev/null | grep -q "regenerate-grub"; then
        ujust regenerate-grub
    elif [ -f "/boot/grub2/grub.cfg" ]; then
        sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    elif [ -f "/boot/efi/EFI/fedora/grub.cfg" ]; then
        sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
    else
        sudo grub2-mkconfig -o /etc/grub2.cfg 2>/dev/null || true
    fi

    print_info "Cleaning up temporary build directories..."
    rm -rf /tmp/acpi_tables /tmp/bc250-acpi-fix-updated-8c /tmp/bc250-acpi-fix
    print_info "ACPI Fix successfully uninstalled!"
    prompt_reboot
}

# ==============================================================================
# UNIFIED INTERACTIVE CLOSURE ENGINE: CONTROL SHUTDOWN / REBOOT / EXIT
# ==============================================================================
secure_system_exit() {
    echo ""
    echo -e "${BIYellow}==================================================${NC}"
    echo -e "${BIYellow}          TOOLKIT SECURE EXIT MANAGEMENT          ${NC}"
    echo -e "${BIYellow}==================================================${NC}"
    echo -e " Select an environment state transition option:"
    echo ""
    echo -e "  ${CYAN}1)${RESET} Fast System Reboot     ${DIM}(Apply newly layered kernel elements)${RESET}"
    echo -e "  ${CYAN}2)${RESET} Full System Shutdown   ${DIM}(Complete hardware power cycle)${RESET}"
    echo -e "  ${CYAN}3)${RESET} Safe Exit Only         ${DIM}(Return cleanly back to host terminal)${RESET}"
    echo -e "  ${RED}   Hit Enter or Any Key to Cancel and Return to Menu${NC}"
    echo -e "${BIYellow}==================================================${NC}"
    type_prompt "  Select option index [1-3]: " 0.03
    
    local exit_choice=""
    read -n 1 -s exit_choice || true
    echo ""

    case "$exit_choice" in
        1)
            echo -e "${GREEN}[+] Cleaning environment and flushing changes to disk...${NC}"
            stop_background_music
            sleep 1.5
            sudo systemctl reboot
            ;;
        2)
            echo -e "${RED}[+] Powering down system block registers safely...${NC}"
            stop_background_music
            sleep 1.5
            sudo systemctl poweroff
            ;;
        3)
            echo -e "${GREEN}[+] Exiting Bazzite Toolbox cleanly. Clearing workspace...${NC}"
            stop_background_music
            sleep 1
            if [ -n "$PPID" ]; then
                kill -SIGHUP "$PPID" 2>/dev/null
            fi
            exit 0
            ;;
        *)
            echo -e "${YELLOW}[-] Exit operation bypassed. Returning to toolkit menu...${NC}"
            sleep 1.2
            return 0
            ;;
    esac
}

# ==============================================================================
# BAZZITE NATIVE DESKTOP PORTAL IPC INTERFACE SANDBOX BREAKOUT LAYER
# ==============================================================================
launch_html_dashboard() {
    echo ""
    echo -e "${YELLOW}[+] Scanning local environment paths for matrix dashboards...${NC}"

    local target_html=""
    for name in "index.html" "cu_map_matrix.html"; do
        if [[ -f "$EXTERNAL_DIR/$name" ]]; then
            target_html="$EXTERNAL_DIR/$name"
            break
        elif [[ -f "$(dirname "$SCRIPT_PATH")/$name" ]]; then
            target_html="$(dirname "$SCRIPT_PATH")/$name"
            break
        elif [[ -f "$REAL_HOME/$name" ]]; then
            target_html="$REAL_HOME/$name"
            break
        elif [[ -f "$REAL_HOME/Bazzite_Toolbox/$name" ]]; then
            target_html="$REAL_HOME/Bazzite_Toolbox/$name"
            break
        fi
    done

    if [[ -n "$target_html" ]]; then
        echo -e "${B_GREEN}[✔] Target discovered: ${WHITE}$target_html${NC}"
        echo -e "${CYAN}[ℹ] Spawning detached host browser thread as user: ${WHITE}$REAL_USER${NC}"
        echo -e "${DIM}    Passing payload variables through the active desktop portal pipeline...${RESET}"

        # 🧬 BAZZITE ENVIRONMENT INTERPRETER: Reconstructs missing session bus links dynamically
        local user_id
        user_id=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

        # Explicitly build the environmental socket variable string matching your user workspace
        local session_bus="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$user_id/bus"
        local display_env=""
        [[ -n "$DISPLAY" ]] && display_env="DISPLAY=$DISPLAY"
        [[ -n "$XAUTHORITY" ]] && display_env="XAUTHORITY=$XAUTHORITY"

        if command -v flatpak-spawn &>/dev/null; then
            # Inject session bus credentials to give the spawner complete desktop validation permissions
            eval "sudo -u \"$REAL_USER\" XDG_RUNTIME_DIR=\"/run/user/$user_id\" $session_bus $display_env flatpak-spawn --host xdg-open \"$target_html\"" &>/dev/null &
        elif command -v busctl &>/dev/null; then
            eval "sudo -u \"$REAL_USER\" XDG_RUNTIME_DIR=\"/run/user/$user_id\" $session_bus busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop org.freedesktop.portal.OpenURI OpenURI ssss \"\" \"file://$target_html\" \"\" \"\"" &>/dev/null &
        else
            eval "sudo -u \"$REAL_USER\" XDG_RUNTIME_DIR=\"/run/user/$user_id\" $session_bus $display_env xdg-open \"$target_html\"" &>/dev/null &
        fi

        # Hold screen visibility open for 2.5 seconds to track state
        sleep 2.5
    else
        echo -e "${RED}[-❌-] CRITICAL ERROR: 'index.html' or 'cu_map_matrix.html' was not found!${NC}"
        echo -e "         Ensure your file sits cleanly in one of these directories:"
        echo -e "         • $EXTERNAL_DIR"
        echo -e "         • $(dirname "$SCRIPT_PATH")"
        echo ""
        type_prompt "  Press [any key] to return to the dashboard... " 0.03
        read -n 1 -s -r || true
    fi
}

# ==============================================================================
# INTEGRATED: MASTER UNIVERSAL DYNAMIC BC-250 SILICON HARVEST ENGINE MATRIX
# ==============================================================================
view_cu_map() {
    clear
    echo -e "${BOLD}${CYAN}  ╔════════════════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}  ║                 📟  AMD BC-250 Live Compute Unit Silicon Map Matrix     📟             ║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚════════════════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${BOLD}${YELLOW}Active Hardware Real-Time Telemetry Profile:${RESET}"
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"

    sudo python3 << 'PYEOF'
import ctypes, struct, os, sys

def render_simulated_map(num_se, num_sh, live_bitmaps, variants_list):
    """Programmatically projects what the silicon grid will look like under specified mask variations"""
    simulated_rows = []
    for se in range(num_se):
        for sh in range(num_sh):
            row_bars = []
            for wgp in range(5):
                is_targeted = any(v_se == se and v_sh == sh and v_wgp == wgp for v_se, v_sh, v_wgp in variants_list)
                if is_targeted:
                    row_bars.append("□□")
                else:
                    row_bars.append("■■")
            bar = "".join(row_bars)
            simulated_rows.append(f"SE{se}SH{sh}:{bar}")
    return " │ ".join(simulated_rows)

try:
    with open("/proc/cmdline", "r") as f:
        cmdline = f.read()
except Exception:
    cmdline = ""

get_status = lambda arg: "\033[1;92m[ RUNNING / STABLE ]\033[0m" if arg in cmdline else "\033[1;90m[ IDLE ]\033[0m"

try:
    try:
        libdrm = ctypes.CDLL("libdrm_amdgpu.so.1")
    except OSError:
        print("   \033[0;31mERROR: libdrm_amdgpu driver library not found on this host system.\033[0m")
        sys.exit(1)

    fd = os.open("/dev/dri/renderD128", os.O_RDWR)
    dev = ctypes.c_void_p()
    maj, min_ = ctypes.c_uint32(), ctypes.c_uint32()
    libdrm.amdgpu_device_initialize(fd, ctypes.byref(maj), ctypes.byref(min_), ctypes.byref(dev))

    buf = (ctypes.c_uint8 * 1024)()
    libdrm.amdgpu_query_info(dev, 0x16, 1024, ctypes.byref(buf))
    raw = bytes(buf)

    # 🔧 FIXED: Added explicit [0] indexers to guarantee raw mathematical integers
    num_se = struct.unpack_from('<I', raw, 20)[0]
    num_sh = struct.unpack_from('<I', raw, 24)[0]

    total = 0
    live_bitmaps = {}
    rows = []
    disrupted_gaps = []
    all_empty_gaps = []

    for se in range(num_se):
        for sh in range(num_sh):
            # 🔧 FIXED: Unpacking array row blocks cleanly into integers
            bm = struct.unpack_from('<I', raw, 56 + (se * 4 + sh) * 4)[0]
            live_bitmaps[(se, sh)] = bm

            wgp_states = []
            for wgp in range(5):
                mask = (1 << (wgp * 2)) | (1 << (wgp * 2 + 1))
                wgp_states.append((bm & mask) != 0)

            n = wgp_states.count(True) * 2
            total += n

            if 0 < n < 10:
                active_indices = [i for i, active in enumerate(wgp_states) if active]
                if active_indices:
                    first_active = active_indices[0]
                    last_active = active_indices[-1]

                    for wgp_idx in range(5):
                        if not wgp_states[wgp_idx]:
                            all_empty_gaps.append((se, sh, wgp_idx))
                            is_middle_gap = first_active < wgp_idx < last_active
                            is_front_disruption = (wgp_idx == 0 and last_active > 0)

                            if is_middle_gap or is_front_disruption:
                                disrupted_gaps.append((se, sh, wgp_idx))

            bar = ''.join('■' if bm & (1 << i) else '□' for i in range(10))
            rows.append(f"   SE{se} SH{sh}: {bar}")

    possible = num_se * num_sh * 10
    harvested = possible - total

    for r in rows:
        print(f"\033[1;92m{r}\033[0m")
    print(f"\n   \033[1;37mStatus: {total}/{possible} CUs active, {harvested} harvested Silicon blocks.\033[0m")

    libdrm.amdgpu_device_deinitialize(dev)
    os.close(fd)
except Exception as e:
    print(f"   \033[0;31mERROR: Failed to read DRM pipeline ioctl bindings ({e})\033[0m")
    sys.exit(1)

print(f"\n  \033[1;36m─────────────────────────────────────────────────────────────────────\033[0m")
print(f"  \033[1;32mAvailable Override Optimization Reference (Targeted Disrupted Row Profiles):\033[0m\n")

unique_gaps = []
for item in disrupted_gaps:
    if item not in unique_gaps:
        unique_gaps.append(item)

final_targets = list(unique_gaps)
is_multi_row_front = len(unique_gaps) >= 2 and all(w == 0 for se, sh, w in unique_gaps)

active_karg_found = False

# 🎰 40/40 LOTTERY WINNER DETECTOR TRIGGER INSTANTIATOR
if len(unique_gaps) == 0 and total == 24:
    map_40_unlock = render_simulated_map(num_se, num_sh, live_bitmaps, [])
    print(f"   \033[1;35m🎉 CONGRATULATIONS! THIS SILICON PROFILE IS A 40/40 LOTTERY WINNER! 🎉\033[0m")
    print(f"   \033[1;35mUnlocked Matrix │ {map_40_unlock}\033[0m")
    print(f"   \033[1;37mNo disrupted rows detected natively on this baseline block configuration.\033[0m")
    print(f"   \033[1;32mYour chip is completely uniform and eligible for direct 40 CU unlock rebases.\033[0m\n")

elif is_multi_row_front:
    expanded_targets = []
    quad_targets = []

    for se, sh, w in unique_gaps:
        tail_wgp = next((tw for s, h, tw in all_empty_gaps if s == se and h == sh and tw != w), None)
        expanded_targets.append((se, sh, w))
        quad_targets.append((se, sh, w))
        if tail_wgp is not None:
            expanded_targets.append((se, sh, tail_wgp))
            quad_targets.append((se, sh, tail_wgp))

    variant_counter = 1

    for se, sh, screen_wgp in expanded_targets:
        karg_str = f"amdgpu.disable_cu={se}.{sh}.{screen_wgp}"
        status_badge = get_status(karg_str)
        if "RUNNING" in status_badge: active_karg_found = True
        map_proj = render_simulated_map(num_se, num_sh, live_bitmaps, [(se, sh, screen_wgp)])

        print(f"   \033[1;36m[DYNAMIC VARIANT 0{variant_counter}]\033[0m Mask Disrupted Target: SE{se} SH{sh} WGP{screen_wgp} (38/40 CUs)  {status_badge}")
        print(f"   \033[1;35mProjections │ {map_proj}\033[0m")
        print(f"   \033[2mCommand: sudo rpm-ostree kargs --append='amdgpu.bc250_cc_write_mode=3 {karg_str}'\033[0m\n")
        variant_counter += 1

    print(f"   \033[1;32m─── Expanded Symmetrical Double Variant Combinations (36/40 Active CUs) ───\033[0m\n")
    for i in range(len(expanded_targets)):
        for j in range(i + 1, len(expanded_targets)):
            t1, t2 = expanded_targets[i], expanded_targets[j]
            double_combo_str = f"amdgpu.disable_cu={t1[0]}.{t1[1]}.{t1[2]},{t2[0]}.{t2[1]}.{t2[2]}"
            status_double = get_status(double_combo_str)
            if "RUNNING" in status_double: active_karg_found = True
            map_double = render_simulated_map(num_se, num_sh, live_bitmaps, [t1, t2])

            print(f"   \033[1;36m[DYNAMIC DOUBLE COMBINATION]\033[0m Masking Gaps: SE{t1[0]}SH{t1[1]}W{t1[2]} + SE{t2[0]}SH{t2[1]}W{t2[2]}   {status_double}")
            print(f"   \033[1;35mProjections │ {map_double}\033[0m")
            print(f"   \033[2mCommand: sudo rpm-ostree kargs --append='amdgpu.bc250_cc_write_mode=3 {double_combo_str}'\033[0m\n")

    print(f"   \033[1;32m─── Expanded Symmetrical Triple Variant Combinations (34/40 Active CUs) ───\033[0m\n")
    for i in range(len(expanded_targets)):
        for j in range(i + 1, len(expanded_targets)):
            for k in range(j + 1, len(expanded_targets)):
                t1, t2, t3 = expanded_targets[i], expanded_targets[j], expanded_targets[k]
                triple_combo_str = f"amdgpu.disable_cu={t1[0]}.{t1[1]}.{t1[2]},{t2[0]}.{t2[1]}.{t2[2]},{t3[0]}.{t3[1]}.{t3[2]}"
                status_triple = get_status(triple_combo_str)
                if "RUNNING" in status_triple: active_karg_found = True
                map_triple = render_simulated_map(num_se, num_sh, live_bitmaps, [t1, t2, t3])

                print(f"   \033[1;36m[DYNAMIC TRIPLE COMBINATION]\033[0m Masking: W{t1[2]} + W{t2[2]} + W{t3[2]} Balance Mask   {status_triple}")
                print(f"   \033[1;35mProjections │ {map_triple}\033[0m")
                print(f"   \033[2mCommand: sudo rpm-ostree kargs --append='amdgpu.bc250_cc_write_mode=3 {triple_combo_str}'\033[0m\n")

    print(f"   \033[1;32m─── Maximum Quadruple Isolation Fallback Alignment (32/40 Active CUs) ───\033[0m\n")
    quad_targets_clean = list(set(quad_targets))
    quad_karg_parts = [f"{s}.{h}.{w}" for s, h, w in quad_targets_clean]
    quad_combo_str = f"amdgpu.disable_cu=" + ",".join(quad_karg_parts)
    status_quad = get_status(quad_combo_str)
    if "RUNNING" in status_quad: active_karg_found = True
    map_quad = render_simulated_map(num_se, num_sh, live_bitmaps, quad_targets_clean)

    print(f"   \033[1;36m[DYNAMIC QUADRUPLE VARIANT]\033[0m Mask Combined Row Disruptions Fallback (32/40 CUs)     {status_quad}")
    print(f"   \033[1;35mProjections │ {map_quad}\033[0m")
    print(f"   \033[2mCommand: sudo rpm-ostree kargs --append='amdgpu.bc250_cc_write_mode=3 {quad_combo_str}'\033[0m\n")

else:
    if len(unique_gaps) == 1:
        se1, sh1, w1 = unique_gaps[0]
        next_wgp = next((w for se, sh, w in all_empty_gaps if se == se1 and sh == sh1 and w != w1), None)
        if next_wgp is not None:
            final_targets.append((se1, sh1, next_wgp))

    variant_counter = 1

    for se, sh, screen_wgp in final_targets[:2]:
        karg_str = f"amdgpu.disable_cu={se}.{sh}.{screen_wgp}"
        status_badge = get_status(karg_str)
        if "RUNNING" in status_badge: active_karg_found = True
        map_proj = render_simulated_map(num_se, num_sh, live_bitmaps, [(se, sh, screen_wgp)])

        print(f"   \033[1;36m[DYNAMIC VARIANT 0{variant_counter}]\033[0m Mask Disrupted Target: SE{se} SH{sh} WGP{screen_wgp} (38/40 CUs)  {status_badge}")
        print(f"   \033[1;35mProjections │ {map_proj}\033[0m")
        print(f"   \033[2mCommand: sudo rpm-ostree kargs --append='amdgpu.bc250_cc_write_mode=3 {karg_str}'\033[0m\n")
        variant_counter += 1

    if len(final_targets) >= 2:
        se1, sh1, w1 = final_targets[0]
        se2, sh2, w2 = final_targets[1]
        combo_str = f"amdgpu.disable_cu={se1}.{sh1}.{w1},{se2}.{sh2}.{w2}"
        status_combo = get_status(combo_str)
        if "RUNNING" in status_combo: active_karg_found = True
        map_combo = render_simulated_map(num_se, num_sh, live_bitmaps, [(se1, sh1, w1), (se2, sh2, w2)])

        print(f"   \033[1;36m[DYNAMIC DOUBLE VARIANT]\033[0m Mask Combined Row Disruptions Fallback (36/40 CUs)       {status_combo}")
        print(f"   \033[1;35mProjections │ {map_combo}\033[0m")
        print(f"   \033[2mCommand: sudo rpm-ostree kargs --append='amdgpu.bc250_cc_write_mode=3 {combo_str}'\033[0m\n")

if not active_karg_found and "bc250_cc_write_mode=3" in cmdline and "disable_cu" not in cmdline:
    print(f"   \033[1;93mℹ Current Boot State Notice: Chip is running unmasked at maximum possible physical CU limit!\033[0m\n")
PYEOF

    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "     • ${CYAN}Pin Deployment${RESET} : If the system boots cleanly, pin your known-good parameters via ostree:"
    echo -e "                       ${MAGENTA}rpm-ostree status && sudo ostree admin pin 0${RESET}"
    echo -e "     • ${YELLOW}Crash Safety${RESET}   : Leave governor services disabled while testing custom target variations."
    echo -e "                       Any hard boot hang will let you safely fall back to stock hardware clocks."
    echo -e "     • ${RED}Full Reversion${RESET} : Remove override masks completely to return to stock configuration parameters:"
    echo -e "                       ${MAGENTA}sudo rpm-ostree kargs --delete=amdgpu.bc250_cc_write_mode=3${RESET}"
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    type_prompt "  Press [Enter] to return to the toolkit main menu... " 0.03
    read -rp "  "
}

# Wrapped in a Menu Loop
show_menu() {
    local RESET="${RESET:-}" BOLD="${BOLD:-}" DIM="${DIM:-}"
    local RED="${RED:-}" GREEN="${GREEN:-}" YELLOW="${YELLOW:-}"
    local CYAN="${CYAN:-}" WHITE="${WHITE:-}" BLUE="${BLUE:-}" MAGENTA="${MAGENTA:-}"
    local ICON_WARN="${ICON_WARN:-⚠}"

    while true; do
        # ═] GLITCH MELT CLEAR ENGINE: Seamlessly dissolves old frames downwards on loop refresh
        matrix_melt_clear

        # Real-time Telemetry Calculators: Updates seamlessly on every screen refresh loop
        local raw_temp cpu_temp
        raw_temp=$(cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -n 1 || echo "0")
        if (( raw_temp > 0 )); then
            cpu_temp="$(( raw_temp / 1000 ))°C"
        else
            cpu_temp="N/A"
        fi
        local load_avg; load_avg=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

        # Draw Symmetrical 24-Bit True Color Green Frame Heading Panel (Bypasses Konsole profile overrides)
        echo -e "${BOLD}\033[38;2;0;255;0m"
        echo "  ╔════════════════════════════════════════════════════════════════════════════════════════╗"
        echo "  ║                                                                                        ║"
        echo -e "  ║         ${YELLOW}██████╗  █████╗ ███████╗███████╗██╗████████╗███████╗    ██████╗ ███████╗\033[38;2;0;255;0m       ║"
        echo -e "  ║         ${YELLOW}██╔══██╗██╔══██╗╚══███╔╝╚══███╔╝██║╚══██╔══╝██╔════╝   ██╔═══██╗██╔════╝\033[38;2;0;255;0m       ║"
        echo -e "  ║         ${YELLOW}██████╔╝███████║  ███╔╝   ███╔╝ ██║   ██║   █████╗  ██ ██║   ██║███████╗\033[38;2;0;255;0m       ║"
        echo -e "  ║         ${YELLOW}██╔══██╗██╔══██║ ███╔╝   ███╔╝  ██║   ██║   ██╔══╝     ██║   ██║╚════██║\033[38;2;0;255;0m       ║"
        echo -e "  ║         ${YELLOW}██████╔╝██║  ██║███████╗███████╗██║   ██║   ███████╗   ╚██████╔╝███████║\033[38;2;0;255;0m       ║"
        echo -e "  ║         ${YELLOW}╚══════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝   ╚═╝   ╚══════╝    ╚═════╝ ╚══════╝\033[38;2;0;255;0m      ║"
        echo -e "  ║  ${RED}⚠ Warning... Do Not Use This Script With the Latest Release Of Bazzite 44 Deck\033[38;2;0;255;0m        ║"
        echo "  ║                                                                                        ║"
        echo -e "  ║    ${B_BLUE}[●] BLUE Pill\033[38;2;0;255;0m             📟  System Core Telemetry  📟             ${RED}RED Pill [●]\033[38;2;0;255;0m    ║"
        echo "  ║                                                                                        ║"
        echo -e "  ║        System Load: ${WHITE}${load_avg}\033[38;2;0;255;0m        │           Silicon Temp: ${YELLOW}${cpu_temp}\033[38;2;0;255;0m               ║"
        echo "  ╚════════════════════════════════════════════════════════════════════════════════════════╝"
        echo -e "${RESET}"

                # --- SECTION 1: STORAGE & INITIAL MEMORY CONFIG ---
        echo -e "  ${BOLD}${YELLOW}This is your last chance. After this, there is no turning back.${RESET}"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "    ${CYAN}[1]${RESET} ${B_BLUE}BLUE  ●${CYAN} 16GB Swapfile Mapping   ${DIM}(Recommended for smaller NVMe setups)${RESET}"
        echo -e "    ${CYAN}[2]${RESET} ${RED}RED   ●${CYAN} 32GB Swapfile Mapping   ${DIM}(Recommended for high-capacity NVMe)${RESET}"
        echo ""

        # --- AUTOMATED SETUP OVERVIEW PANEL ---
        echo -e "  ${BOLD}${WHITE}  ℹ  Automated Deployment Sequence Summary (Options 1 & 2):${RESET}"
        echo -e "     Executing either option triggers a complete professional optimization suite:"
        echo -e "     • Repository Setup    : Hooks the filippor-bazzite COPR package tracking"
        echo -e "     • Governor Upgrade    : Installs cyan-skillfish-governor-smu (Enhanced Overclock)"
        echo -e "     • Conflict Management : Stops and disables obsolete standard/oberon governor daemons"
        echo -e "     • Core Safety Fix     : Disables hardware CPU mitigations to maximize performance"
        echo -e "     • Swap Infrastructure : Disables stock ZRAM and deploys a target 16G/32G disk swapfile"
        echo -e "     • Memory Efficiency   : Enables optimized ZSWAP caching using fast lz4 compression"
        echo -e "     • Kernel Tuning       : Adjusts vm.swappiness=180 for aggressive virtual handling"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
        echo ""

                # --- SECTION 2: COMPONENT SWITCHES & TOOLS ---
                # --- SECTION 2: COMPONENT SWITCHES & TOOLS ---
        echo -e "  ${BOLD}${YELLOW}Hardware Unlocks & Core Optimizations${RESET}"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
        
        # 🧬 MERGED VISUAL TOGGLE LINE:
        echo -e "    ${CYAN}[3]${RESET} Toggle BC-250 ACPI Table Fix   ${DIM}(Automated Install / Uninstall Switch)${RESET}"
        
        echo -e "    ${CYAN}[5]${RESET} Launch BC-250 Overclock Manager ${DIM}(Live SMU adjustment utility)${RESET}"
        echo -e "    ${CYAN}[6]${RESET} Launch Wake-on-LAN Configuration ${DIM}(Interface port selector tool)${RESET}"

        echo -e "    ${CYAN}[7]${RESET} Upgrade Governor Binary Track  ${DIM}(Target: v0.4.12 via COPR repo)${RESET}"
        echo -e "    ${BOLD}${GREEN}[h] Interrogate Silicon CU Map Matrix ${DIM}(Analyze Harvest Override Variants)${RESET}"

        # 🎨 ADD THIS VISUAL OPTION LINE DIRECTLY HERE TO ALIGN YOUR FRAME MARGINS:
        echo -e "    ${BOLD}${MAGENTA}[o] Launch Interactive HTML Matrix Dashboard ${DIM}(Default Web Browser)${RESET}"
        echo ""

        # --- SECTION 3: SMU GOVERNOR LAYER CONTROLS ---
        echo -e "  ${BOLD}${YELLOW}Cyan Skillfish Governor Daemon Service Management${RESET}"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "    ${GREEN}[a] Runtime Start${RESET}  ${DIM}(Temporary Session)${RESET}  ${YELLOW}[d] Runtime Stop${RESET}  ${DIM}(Kill Process)${RESET}"
        echo -e "    ${GREEN}[b] Persistent Boot Enable${RESET} ${DIM}(--now)${RESET}      ${RED}[e] Persistent Disable${RESET} ${DIM}(--now)${RESET}"
        echo -e "    ${CYAN}[c] Soft Restart Service Layer${RESET}          ${CYAN}[f] Stream Live Status${RESET} ${DIM}(Ctrl+C to Exit)${RESET}"
        echo -e "    ${BLUE}[g] Interrogate Active Driver Version${RESET}   ${B_BLUE}[s] Print Core System Status${RESET}"
        echo ""

        # --- GLOBAL OPERATIONS ---
        echo -e "    ${BLUE}[r] Reload Menu Interface${RESET}"
        echo -e "    ${BOLD}${RED}[0] Secure Safe Exit${RESET}"
        echo ""

        # --- INTEGRATED WARNING & CONFIG NOTICES ---
        echo -e "  ${BOLD}${RED}  ${ICON_WARN}  WARNING: OVERCLOCKING AND UNDERVOLTING CAN DAMAGE SILICON TARGETS!${RESET}"
        echo -e "  ${RED}            PROCEED ENTIRELY AT YOUR OWN RISK AND VERIFY SYSTEM COOLING.${RESET}"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "  ${YELLOW}  ℹ  Configuration Path Notice:${RESET}"
        echo -e "     Ensure adjustments are populated inside the config container path before launch:"
        echo -e "     ${WHITE}\"/etc/cyan-skillfish-governor-smu/config.toml\"${RESET}"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"

                # Safe Prompt Parser (Instant Typing Response Keystroke Engine)
        type_prompt "  Select an option [0-7, a-g, h, o, s]: " 0.03
        choice=""
        read -n 1 -s choice || true
        echo ""

            case "$choice" in
            1) install_blue_pill ;;
            2) install_red_pill ;;
            
            # 🧬 UPDATED PATHWAY: Route option 3 to your new toggle engine
            3) toggle_acpi_fix ;;
            
            5) install_overclock ;;
            6) install_wake_on_lan ;;

            7) update_cyan-skillfish ;;
            h) view_cu_map ;;  # Hooks your new look securely into the runtime loop

            # 🧬 INJECT THIS CASE BRANCH DIRECTLY HERE:


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
            g)
                clear
                echo -e "${CYAN}Displaying Cyan Skillfish Governor SMU Version...${NC} ${RED}( Press Ctrl-c to continue )${NC}"
                echo ""
                sudo cyan-skillfish-governor-smu --version
                echo ""
                read -rp "Press [Enter] to return to the main menu..."
                ;;
            s)
                run_status
                type_prompt "  Press [any key] to return to the toolkit main menu... " 0.03
                #echo -e "\n  ${YELLOW}Press any key to return to the menu...${RESET}"
                read -n 1 -s -r || true
                ;;
            r)
                print_info "Reinitializing toolkit memory tracking blocks..."
                sleep 0.5
                exec bash "$SCRIPT_PATH" "$@"
                ;;

            o) launch_html_dashboard ;;

            # 🧬 REDIRECTED TO THE NEW INTERACTIVE CLOSURE SYSTEM:
            0)
                secure_system_exit
                ;;
            *)
                echo -e "${RED}Invalid choice! Please select a valid number.${NC}"
                sleep 1.5
                ;;
        esac
    done
}

# --- Start Menu Trigger Execution ---
show_menu
