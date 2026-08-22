#!/usr/bin/env bash

clear
# Color definitions
RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"

RED='\033[0;31m'
B_RED='\033[1;31m'   # Bold Red for high-visibility Red Pill elements
GREEN='\033[0;32m'
B_GREEN='\033[0;92m\' # Bold Green for verified/active status
YELLOW='\033[1;33m'
B_BLUE='\033[1;34m'  # Bold Blue for high-visibility Blue Pill elements
B_VIOLET='\033[1;35m' # Bold Violet for ACPI Fix elements
CYAN='\033[0;36m'
BIBlack='\033[1;90m'       # Black
BIRed='\033[1;91m'         # Red
BIGreen='\033[1;92m'       # Green
BIYellow='\033[1;93m'      # Yellow
BIBlue='\033[1;94m'        # Blue
BIPurple='\033[1;95m'      # Purple
BICyan='\033[1;96m'        # Cyan
BIWhite='\033[1;97m'       # White
NC='\033[0m' # No Color (Reset)

BG_HEADER="\e[48;5;235m"
# Ensure paths capture the local user context accurately
REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || whoami)}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
[[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]] && REAL_HOME="/root"

# Universal WAV target path
AUDIO_FILE="$REAL_HOME/Bazzite_Toolbox/Wake_on_LAN/Red-Pill-Blue-Pill.wav"
MUSIC_LOCK_FILE="$REAL_HOME/.bc250-toolkit-music.pid"

start_background_music() {
    if [[ -f "$AUDIO_FILE" ]] && [[ ! -f "$MUSIC_LOCK_FILE" ]]; then
        local user_id; user_id=$(id -u "$REAL_USER")

        # 1. Start the infinite audio playback loop
        (
            while true; do
                sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$user_id" pw-play "$AUDIO_FILE"
            done
        ) &>/dev/null &
        echo $! > "$MUSIC_LOCK_FILE" || true

        # 2. Spawn a detached 30-second automated fade-out timer thread
        (
            # Wait for 30 seconds while the music plays at full volume
            sleep 71

            # Start the fade-out sequence: Lower volume gradually over 5 seconds
            # Query the PipeWire system to find our specific pw-play playback nodes
            local nodes; nodes=$(sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$user_id" pw-cli list-objects Node 2>/dev/null | grep -B 2 "pw-play" | awk -F'= ' '/id/ {print $2}' | tr -d ',')

            if [[ -n "$nodes" ]]; then
                # Step down the volume multiplier cleanly from 100% to 0%
                for vol in 0.8 0.6 0.4 0.2 0.1 0.0; do
                    for node in $nodes; do
                        sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$user_id" pw-cli s "$node" Props "{ volume: $vol }" &>/dev/null || true
                    done
                    sleep 0.8  # Smooth transition spacing interval between volume steps
                done
            fi

            # Cleanly terminate the audio loop process once volume hits zero
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
        if [[ -n "$target_pid" ]]; then
            kill -9 "$target_pid" 2>/dev/null || true
        fi
        killall pw-play 2>/dev/null || true
        rm -f "$MUSIC_LOCK_FILE" 2>/dev/null || true
    fi
}

# Ensure clean exit handling
trap stop_background_music EXIT

# --- Main Execution ---
start_background_music

clear
# FIX: Swapped to 1;97m (Absolute Bold White) to bypass terminal color table overrides
echo -e ${DIM}
echo -e " ${BIGreen} ╔══════════════════════════════════════════════════════════════════════════╗"${BIGreen}
echo -e " ${BIGreen} ║                                                                          ║"${BIGreen}
echo -e " ${BIGreen} ║                     █ █ █ █▀▀ █   █▀▀ █▀█ █▄█ █▀▀                        ║"${BIGreen}
echo -e " ${BIGreen} ║                     ▀▄▀▄▀ ██▄ █▄▄ █▄▄ █▄█ █ █ ██▄                        ║"${BIGreen}
echo -e " ${BIGreen} ║                                                                          ║"${BIGreen}
echo -e " ${BIGreen} ╚══════════════════════════════════════════════════════════════════════════╝"${BIGreen}
echo -e ${CYAN}

echo -e ${BIGreen}
read -rp "  Press Enter to continue..." dummy_input
echo -e ${BIGreen}





# --- Swap Allocation Global Targets ---
SWAPFILE_PATH="/var/swap/swapfile"  # Bazzite's standard BTRFS swapfile target path
SWAPFILE_STOCK_SIZE_MB=4096         # Stock 4GB layout baseline

# Verify root/sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run with sudo or as root."
    echo -e "Please run: sudo bash $0${NC}"
    exit 1
fi

# Start
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
    echo "  ╔═════════════════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                             ║"
    echo -e "  ║  ${YELLOW}██████╗  █████╗ ███████╗███████╗██╗████████╗███████╗    ██████╗ ███████╗${CYAN}   ║"
    echo -e "  ║  ${YELLOW}██╔══██╗██╔══██╗╚══███╔╝╚══███╔╝██║╚══██╔══╝██╔════╝   ██╔═══██╗██╔════╝${CYAN}   ║"
    echo -e "  ║  ${YELLOW}██████╔╝███████║  ███╔╝   ███╔╝ ██║   ██║   █████╗  ██ ██║   ██║███████╗${CYAN}   ║"
    echo -e "  ║  ${YELLOW}██╔══██╗██╔══██║ ███╔╝   ███╔╝  ██║   ██║   ██╔══╝     ██║   ██║╚════██║${CYAN}   ║"
    echo -e "  ║  ${YELLOW}██████╔╝██║  ██║███████╗███████╗██║   ██║   ███████╗   ╚██████╔╝███████║${CYAN}   ║"
    echo -e "  ║  ${YELLOW}╚══════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝   ╚═╝   ╚══════╝    ╚═════╝ ╚══════╝${CYAN}  ║"
    echo "  ║                                                                             ║"
    echo "  ║                             BC250 System Status                             ║"
    echo "  ║                                                                             ║"
    echo "  ╚═════════════════════════════════════════════════════════════════════════════╝"
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
    # Calculate visual width by stripping multi-byte chars and measuring byte difference
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
    # Checks if the persistent systemd service for core unlocking is enabled
    systemctl is-enabled bc250-core-unlock.service &>/dev/null
}

core_unlock_cores_active() {
    # If the system registers 16 threads, the 8c/16t core layout is active
    [[ "$(nproc --all 2>/dev/null)" -eq 16 ]]
}

ram_split_installed() {
    # Checks if the custom memory splitting rules are active in boot arguments or configurations
    rpm-ostree kargs 2>/dev/null | grep -q "ttm.pages_limit" || [[ -f /etc/modprobe.d/bc250-mem.conf ]]
}

zram_currently_disabled() {
    # Checks if the system block allocation for zram0 is missing or disabled
    [[ ! -d /sys/block/zram0 ]]
}

zswap_currently_on() {
    # Directly checks the running kernel module parameters for ZSWAP execution state
    [[ "$(cat /sys/module/zswap/parameters/enabled 2>/dev/null || echo "N")" == "Y" ]]
}

swapfile_size_mb() {
    if [[ -f "$SWAPFILE_PATH" ]]; then
        # Returns the actual size in megabytes using standard block allocation metrics
        echo $(( $(stat -c%s "$SWAPFILE_PATH" 2>/dev/null || echo 0) / 1024 / 1024 ))
    else
        echo 0
    fi
}

core_unlock_persist_installed() {
    systemctl is-enabled bc250-core-unlock.service &>/dev/null
}

core_unlock_cores_active() {
    [[ "$(nproc --all 2>/dev/null)" -eq 16 ]]
}

cu_find_umr() {
    # On Bazzite, check if the AMD UMR debugging tool exists in the runtime environment
    command -v umr &>/dev/null
}

acpi_fix_installed() {
    # On Bazzite, checks if custom ACPI table overrides exist or if the custom DSDT directory is populated
    [[ -d /sys/firmware/acpi/tables/user ]] || [[ -f /etc/tmpfiles.d/acpi-override.conf ]]
}

sensors_active_driver() {
    if lsmod | grep -q "^nct6687"; then echo "nct6687"; else echo "none"; fi
}

# ==============================================================================
# UNIFIED MEMORY SYSTEM (RAM/VRAM CARVE-OUT MANAGEMENT)
# ==============================================================================
# The BC-250 runs a 16GB Unified Memory Architecture (UMA) shared between the
# CPU and GPU. The default BIOS locks down half of the machine's memory—creating
# an inflexible 8GB RAM / 8GB VRAM split even when the machine is idle.
#
# Lowering this allocation (stored securely inside the battery-backed extended CMOS)
# maximizes available system memory. While a 512MB floor returns nearly all RAM to
# the pool when a game is closed, intensive compositor flips can occasionally trigger
# framebuffer allocation failures. Assigning a balanced 6GB (6144MB) base pool or
# higher is recommended to maintain rock-solid system stability under Gamescope.
#
# To accommodate demanding games requiring 8GB+ allocations without display crashes,
# the script also pairs your hardware base split with the 'ttm.pages_limit' kernel
# parameter to override and lift the dynamic graphics allocation ceilings.
#
# Modded BIOS flash profiles are obsolete. Changes are managed via the integrated
# fanoush/bc250_memcfg binary utility, compiled natively from source at runtime.
# Documentation: https://elektricm.github.io/amd-bc250-docs/bios/vram/
# ==============================================================================

RAM_SPLIT_DIR="$EXTERNAL_DIR/bc250_memcfg"
RAM_SPLIT_BIN="$RAM_SPLIT_DIR/bc250memcfg"
RAM_SPLIT_DEFAULT_UMA_MB=512
RAM_SPLIT_STOCK_UMA_MB=8192
RAM_SPLIT_DEFAULT_TTM_PAGES=3145728   # ~12GB dynamic VRAM ceiling (4KiB pages)

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
        # gcc may be present but glibc headers (stdio.h etc.) missing/stripped
        # on the SteamOS overlay -- force-reinstall rather than relying on
        # pacman's "already installed" bookkeeping (which --needed respects).
        print_info "gcc / libc headers missing or broken — (re)installing base-devel + glibc..."
        steamos_writable 'pacman -Sy --noconfirm base-devel glibc' || {
            fail_with_log "Failed to install gcc/glibc." "RAM/VRAM Split — gcc"
            return 1
        }
    fi
    if ! ram_split_gcc_can_compile; then
        fail_with_log "gcc still cannot compile a plain C program after reinstalling base-devel/glibc (missing /usr/include headers on this SteamOS image). Check 'pacman -Qo /usr/include/stdio.h' and 'ls /usr/include/stdio.h'." "RAM/VRAM Split — gcc headers"
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

ram_split_installed() {
    [[ -f "$GRUB_DEFAULT" ]] && grep -qE 'GRUB_CMDLINE_LINUX_DEFAULT=.*ttm\.pages_limit=' "$GRUB_DEFAULT" 2>/dev/null
}


# ... (rest of your helpers: ram_split_installed, zram_currently_disabled, etc.)

run_status() {
    print_banner
    # ... (the rest of your run_status logic)
}


run_status() {
    print_banner
    print_section "System Status"

    # --- Strict Mode Safety Fallbacks ---
    # Icons/colors (define as needed)
    local ICON_OK="✔"
    local ICON_WARN="⚠"
    local ICON_OK="${ICON_OK:-${GREEN}✓${RESET}}"
    local ICON_WARN="${ICON_WARN:-${YELLOW}⚠${RESET}}"
    local ICON_ERR="${ICON_ERR:-${RED}✗${RESET}}"
    local DIM="${DIM:-}"
    local RESET="${RESET:-}"
    local GREEN="${GREEN:-}"
    local YELLOW="${YELLOW:-}"
    local RED="${RED:-}"
    local CYAN="${CYAN:-}"
    local BOLD="${BOLD:-}"
    local WHITE="${WHITE:-}"

    # Bazzite uses systemd-boot or GRUB depending on the hardware platform
    local BOOTLOADER
    BOOTLOADER="$(detect_bootloader 2>/dev/null || echo "unknown")"
    local CPU_CONF="/etc/bc250-smu-oc.conf"
    local GPU_CONF="/etc/cyan-skillfish-governor-smu/config.toml"

    # --- System ---
    echo -e "  ${BOLD}${YELLOW}System${RESET}"
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"

    # Bazzite/SteamOS native session detection
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

    if [[ "$boot_relogin" == "false" ]]; then
        boot_login="${DIM}password required${RESET}"
    else
        boot_login="${DIM}no password${RESET}"
    fi

    # Dynamic Wake-on-LAN Diagnostic Interrogation Layer
     # Dynamic Wake-on-LAN Diagnostic Interrogation Layer
    local wol_icon="$ICON_WARN"
    local wol_label="${YELLOW}deactivated${RESET}"
    local wol_enabled=false
    local wol_setting

    # Loop sequentially through all registered NetworkManager connections
    while IFS= read -r conn; do
        [[ -z "$conn" ]] && continue

        # Interrogate the individual profile's low-level hardware wake properties
        wol_setting=$(nmcli -g 802-3-ethernet.wake-on-lan connection show "$conn" 2>/dev/null | tr '[:upper:]' '[:lower:]')

        # If any connection maps the magic packet token, trigger the status flag
        if [[ "$wol_setting" == *magic* ]]; then
            wol_enabled=true
            break
        fi
    done < <(nmcli -t -f NAME connection show 2>/dev/null)

    # Set universal grid dashboard output based on detection flags
    if $wol_enabled; then
        wol_icon="$ICON_OK"
        wol_label="${GREEN}activated${RESET}"
    else
        wol_icon="$ICON_WARN"
        wol_label="${YELLOW}deactivated${RESET}"
    fi

    # UNIVERSAL ALIGNMENT: 22-character padding locks all icons into a perfect grid
    echo -e "  ${CYAN}Boot Mode${RESET}             ${boot_mode}  ${boot_login}"
    echo -e "  ${CYAN}OS${RESET}                    $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo -e "  ${CYAN}Version${RESET}               $(cat /etc/os-release | grep -E '^(VERSION)=' | cut -d= -f2 | tr -d '"')"
    echo -e "  ${CYAN}Kernel${RESET}                $(uname -r)"
    echo -e "  ${CYAN}Wake-on-LAN${RESET}           ${wol_icon} ${wol_label}"
    echo ""

    # --- Overclock Profile ---
    print_section "Overclock"

    local cpu_preset="None"
    local cpu_profile="No Active Config"

    if [[ -f "$CPU_CONF" ]]; then
        cpu_preset=$(oc_match_preset 2>/dev/null || echo "Custom")
        cpu_profile=$(oc_active_profile 2>/dev/null || echo "Active Profile")
        echo -e "  ${DIM}Active: ${cpu_preset} — ${cpu_profile}${RESET}"
    else
        echo -e "  ${DIM}Active: ${cpu_preset} — ${cpu_profile}${RESET}"
    fi
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"

    if [[ -f "$CPU_CONF" ]]; then
        local cpu_freq cpu_scale cpu_temp
        cpu_freq=$(awk -F'= ' '/^frequency/{sub(/#.*/, "", $2); print $2}' "$CPU_CONF" | tr -d ' ')
        cpu_scale=$(awk -F'= ' '/^scale/{sub(/#.*/, "", $2); print $2}' "$CPU_CONF" | tr -d ' ')
        cpu_temp=$(awk -F'= ' '/^max_temperature/{sub(/#.*/, "", $2); print $2}' "$CPU_CONF" | tr -d ' ')
        echo -e "  ${CYAN}CPU Profile${RESET}           ${ICON_OK} ${cpu_freq}MHz  scale ${cpu_scale}  max ${cpu_temp}°C"
    else
        echo -e "  ${CYAN}CPU Profile${RESET}           ${ICON_WARN} ${DIM}config not found${RESET}"
    fi

    if [[ -f "$GPU_CONF" ]]; then
        local gpu_freq gpu_throttle
        gpu_freq=$(awk -F'= ' '/^frequency/{sub(/#.*/, "", $2); print $2}' "$GPU_CONF" | tr -d ' ' | tail -1)
        gpu_throttle=$(awk -F'= ' '/^throttling /{sub(/#.*/, "", $2); print $2}' "$GPU_CONF" | tr -d ' ')
        echo -e "  ${CYAN}GPU Profile${RESET}           ${ICON_OK} ${gpu_freq}MHz  throttle ${gpu_throttle}°C"
    else
        echo -e "  ${CYAN}GPU Profile${RESET}           ${ICON_WARN} ${DIM}config not found${RESET}"
    fi

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

    local gpu_icon gpu_label
    if systemctl is-active --quiet cyan-skillfish-governor-smu.service 2>/dev/null; then
        gpu_icon="$ICON_OK"
        gpu_label="${GREEN}activated${RESET}"
    else
        gpu_icon="$ICON_WARN"
        gpu_label="${YELLOW}deactivated${RESET}"
    fi
    echo -e "  ${CYAN}GPU Service${RESET}           ${gpu_icon} ${gpu_label}"
    echo ""

    # --- Hardware Unlocks ---
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

    if cu_find_umr; then
        local active_bitmap
        active_bitmap=$(sudo umr -r *.gfx1030.mmSPI_SHADER_PG_CONFIG_CU 2>/dev/null | awk '{print $2}' | tr -d '[:space:]')

        if [[ -n "$active_bitmap" ]]; then
            local cu_total=0
            cu_total=$(printf "%d" "$active_bitmap" 2>/dev/null || echo "0")

            if [[ "$cu_total" -eq 0 ]]; then
                cu_total=38
            fi

            local cu_color cu_icon cu_warn_msg=""
            if [ "$cu_total" -gt 24 ]; then
                cu_icon="$ICON_WARN"
                cu_color="$YELLOW"
                cu_warn_msg=" ${YELLOW}⚠  CUs unlocked — verify power and cooling${RESET}"
            else
                cu_icon="$ICON_OK"
                cu_color="$GREEN"
            fi
            echo -e "  ${CYAN}Active CUs${RESET}            ${cu_icon} ${cu_color}${BOLD}${cu_total}/40${RESET}  ${DIM}(default 24, max 40)${RESET}${cu_warn_msg}"
        else
            echo -e "  ${CYAN}Active CUs${RESET}            ${ICON_WARN} ${YELLOW}38/40${RESET}  ${DIM}(default 24, max 40)${RESET} ${YELLOW}⚠ Unlocked — verify power/cooling${RESET}"
        fi
    else
        echo -e "  ${CYAN}Active CUs${RESET}            ${ICON_WARN} ${DIM}umr not installed${RESET}"
    fi

    if ram_split_installed; then
        local uma_now
        uma_now=$(ram_split_current_uma 2>/dev/null)
        echo -e "  ${CYAN}RAM/VRAM Split${RESET}        ${ICON_OK} ${GREEN}UMA_SIZE=${uma_now:-?}MB${RESET}, ttm.pages_limit ceiling active"
    else
        echo -e "  ${CYAN}RAM/VRAM Split${RESET}        ${DIM}– not installed (stock split)${RESET}"
    fi
    echo ""
    # --- Swap & ZRAM/ZSWAP ---
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

    # --- Sensors & Fan Control ---
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
        cc_svc_state="activated"
        cc_icon="$ICON_OK"
        cc_color="$GREEN"
    else
        cc_svc_state="deactivated"
        cc_icon="$ICON_WARN"
        cc_color="$YELLOW"
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

    # --- Community Fixes ---
    print_section "Community Fixes"

    local acpi_icon acpi_color acpi_label
    if acpi_fix_installed; then
        if compgen -G /sys/devices/system/cpu/cpu0/cpufreq >/dev/null; then
            acpi_icon="$ICON_OK"; acpi_color="$GREEN"; acpi_label="activated (C/P-states present)"
        else
            acpi_icon="$ICON_WARN"; acpi_color="$YELLOW"; acpi_label="installed — reboot pending"
        fi
    else
        acpi_icon="$DIM"; acpi_color="$DIM"; acpi_label="not installed"
    fi
    echo -e "  ${CYAN}ACPI Fix${RESET}              ${acpi_icon} ${acpi_color}${acpi_label}${RESET}"

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

    # Always drop the broken legacy menu configuration overrides if they exist
    rm -f "$OLD_DIRECTORY" "$OLD_MENU"

    refresh_desktop_database
    print_info "Shortcut installed successfully!"
}

manage_shortcut_prompt() {
    # Check if a preference already exists in the config file
    if [ -f "$CONFIG_FILE" ]; then
        local saved_pref
        saved_pref=$(grep "START_MENU_SHORTCUT=" "$CONFIG_FILE" | cut -d= -f2)

        if [ "$saved_pref" == "false" ]; then
            force_remove_shortcut
            print_info "Skipping shortcut creation (User opted out in configuration)."
            return 0
        elif [ "$saved_pref" == "true" ]; then
            create_start_menu_shortcut
            return 0
        fi
    fi

    # If no preference is saved, trigger the question
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

# Rest of your script logic starts here...
echo -e "${GREEN}Starting Bazzite Toolbox Core UI...${NC}"
#End

# =====================================================================
# 2. AUTO-UPDATE MECHANISM (WITH SILENT OFFLINE FAIL)
# =====================================================================
GITHUB_RAW_URL="https://github.com/Forbidden-Darkness/Bazzite_Toolbox/raw/refs/heads/main/start.sh"

if [ "$1" != "--no-update" ] && [ "$1" != "--updated" ]; then
    # Completely silent connectivity check. Fails instantly if offline.
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
                # Re-executes the newly downloaded file and hands over the flag
                exec bash "$SCRIPT_PATH" --updated "$@"
            fi
        fi
        rm -f "$TEMP_FILE"
    fi
fi

# =====================================================================
# YOUR MAIN SCRIPT LOGIC CONTINUES BELOW
# =====================================================================
print_info "Starting main script workflow..."

# ... Rest of your tool logic goes here ...

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

# Run the optional shortcut menu before opening the primary toolkit
ask_desktop_shortcut

# Run the shortcut configuration function
ensure_desktop_shortcut

# ---------------------------------
# Function to pause and offer a Cancel Reboot option
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
            echo -e "${YELLOW}Reboot cancelled. Returning to main menu. Remember to reboot manually later for changes to take effect.${NC}"
            sleep 2
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

# Function to handle ACPI Override Fix
apply_acpi_fix() {
    echo -e "${B_VIOLET}=== Executing BC-250 ACPI Fix ===${NC}"

    cd /tmp || return 1
    rm -rf acpi_tables/kernel/firmware/acpi
    git clone https://github.com/mendesrr/bc250-acpi-fix-updated-8c.git
    cd bc250-acpi-fix-updated-8c

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

    sudo cp SSDT_ACPI.cpio /boot/.
    echo 'GRUB_EARLY_INITRD_LINUX_CUSTOM="../../SSDT_ACPI.cpio"' | sudo tee -a /etc/default/grub
    ujust regenerate-grub

    echo -e "${B_VIOLET}=== Installing kernel-tools (cpupower) ===${NC}"
    rpm-ostree install kernel-tools

    prompt_reboot
}

# Function to handle ACPI Override Removal (Uninstaller)
remove_acpi_fix() {
    echo -e "${B_VIOLET}=== Removing BC-250 ACPI Fix ===${NC}"

    # 1. Remove the custom early initrd configuration line from /etc/default/grub
    if grep -q "GRUB_EARLY_INITRD_LINUX_CUSTOM" /etc/default/grub; then
        print_info "Removing GRUB_EARLY_INITRD_LINUX_CUSTOM from /etc/default/grub..."
        sudo sed -i '/GRUB_EARLY_INITRD_LINUX_CUSTOM/d' /etc/default/grub
    else
        print_warning "No GRUB_EARLY_INITRD_LINUX_CUSTOM line found in /etc/default/grub."
    fi

    # 2. Delete the compiled archive from /boot
    if [ -f "/boot/SSDT_ACPI.cpio" ]; then
        print_info "Deleting /boot/SSDT_ACPI.cpio..."
        sudo rm -f /boot/SSDT_ACPI.cpio
    else
        print_warning "File /boot/SSDT_ACPI.cpio not found."
    fi

    # 3. Regenerate GRUB configurations via ujust
    print_info "Regenerating GRUB configuration..."
    if command -v ujust &> /dev/null; then
        ujust regenerate-grub
    else
        sudo grub2-mkconfig -o /etc/grub2.cfg
    fi

    # 4. Clean up temporary directories / cloned files
    print_info "Cleaning up temporary build directories..."
    rm -rf /tmp/acpi_tables /tmp/bc250-acpi-fix-updated-8c /tmp/bc250-acpi-fix

    print_info "ACPI Fix successfully uninstalled!"
    prompt_reboot
}

# Wrapped in a Menu Loop
show_menu() {
    # Ensure local terminal variables exist to protect strict set -u bounds
    local RESET="${RESET:-}" BOLD="${BOLD:-}" DIM="${DIM:-}"
    local RED="${RED:-}" GREEN="${GREEN:-}" YELLOW="${YELLOW:-}"
    local CYAN="${CYAN:-}" WHITE="${WHITE:-}" BLUE="${BLUE:-}" MAGENTA="${MAGENTA:-}"
    local ICON_WARN="${ICON_WARN:-⚠}"
    # Example implementation line to drop inside your main clear menu loop:
    # DYNAMIC TELEMETRY CALCULATOR: Sweeps the kernel hardware matrix for real-time metrics
        local raw_temp cpu_temp
        raw_temp=$(cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -n 1 || echo "0")
        if (( raw_temp > 0 )); then
            cpu_temp="$(( raw_temp / 1000 ))°C"
        else
            cpu_temp="N/A"
        fi

        local load_avg; load_avg=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

        # UNIVERSAL GEOMETRY: Precision padded to line up flawlessly with your 78-character panel walls
        # echo -e "  ║    System Load: ${WHITE}${load_avg}${CYAN}          │       Silicon Temp: ${YELLOW}${cpu_temp}${CYAN}      ║"



    while true; do
        clear

    echo -e "${BOLD}${CYAN}"
    echo "  ╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                               ║"
    echo -e "  ║   ${YELLOW}██████╗  █████╗ ███████╗███████╗██╗████████╗███████╗    ██████╗ ███████╗${CYAN}    ║"
    echo -e "  ║   ${YELLOW}██╔══██╗██╔══██╗╚══███╔╝╚══███╔╝██║╚══██╔══╝██╔════╝   ██╔═══██╗██╔════╝${CYAN}    ║"
    echo -e "  ║   ${YELLOW}██████╔╝███████║  ███╔╝   ███╔╝ ██║   ██║   █████╗  ██ ██║   ██║███████╗${CYAN}    ║"
    echo -e "  ║   ${YELLOW}██╔══██╗██╔══██║ ███╔╝   ███╔╝  ██║   ██║   ██╔══╝     ██║   ██║╚════██║${CYAN}    ║"
    echo -e "  ║   ${YELLOW}██████╔╝██║  ██║███████╗███████╗██║   ██║   ███████╗   ╚██████╔╝███████║${CYAN}    ║"
    echo -e "  ║   ${YELLOW}╚══════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝   ╚═╝   ╚══════╝    ╚═════╝ ╚══════╝${CYAN}   ║"
    echo "  ║                                                                               ║"
    echo -e "  ║    ${B_BLUE}[●] BLUE Pill${CYAN}                                            ${RED}RED Pill [●]${CYAN}      ║"
    echo "  ║                                                                               ║"
    echo "  ╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "  ║    System Load: ${WHITE}${load_avg}${CYAN}          │       Silicon Temp: ${YELLOW}${cpu_temp}${CYAN}          ║"
    echo -e "${RESET}"


        # Clean Geometric Heading Panel
        #echo -e "  ${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════╗${RESET}"
        #echo -e "  ${BOLD}${CYAN}║                  AMD BC-250 OPTIMIZATION TOOLKIT                  ║${RESET}"
        #echo -e "  ${BOLD}${CYAN}║                       System Management Menu                      ║${RESET}"
        #echo -e "  ${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════╝${RESET}"

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
        echo -e "  ${BOLD}${YELLOW}Hardware Unlocks & Core Optimizations${RESET}"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "    ${CYAN}[3]${RESET} Inject BC-250 ACPI Table Fix   ${DIM}(Restores C/P-state voltage loops)${RESET}"
        echo -e "    ${CYAN}[4]${RESET} Revert BC-250 ACPI Table Fix   ${DIM}(System Uninstaller Mode)${RESET}"
        echo -e "    ${CYAN}[5]${RESET} Launch BC-250 Overclock Manager ${DIM}(Live SMU adjustment utility)${RESET}"
        echo -e "    ${CYAN}[6]${RESET} Launch Wake-on-LAN Configuration ${DIM}(Interface port selector tool)${RESET}"
        echo -e "    ${CYAN}[7]${RESET} Upgrade Governor Binary Track  ${DIM}(Target: v0.4.12 via COPR repo)${RESET}"
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
        echo -e "    ${BOLD}${RED}[0] Secure Safe Exit${RESET}"    
        echo -e "    ${BLUE}[r] Reload Menu Interface${RESET}"
        echo -e "    ${BOLD}${RED}[0] Secure Safe Exit${RESET}"
        echo ""

        echo ""

        # --- INTEGRATED WARNING & CONFIG NOTICES ---
        echo -e "  ${BOLD}${RED}  ${ICON_WARN}  WARNING: OVERCLOCKING AND UNDERVOLTING CAN DAMAGE SILICON TARGETS!${RESET}"
        echo -e "  ${RED}            PROCEED ENTIRELY AT YOUR OWN RISK AND VERIFY SYSTEM COOLING.${RESET}"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "  ${YELLOW}  ℹ  Configuration Path Notice:${RESET}"
        echo -e "     Ensure adjustments are populated inside the config container path before launch:"
        echo -e "     ${WHITE}\"/etc/cyan-skillfish-governor-smu/config.toml\"${RESET}"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"

        # Safe Prompt Parser
        choice=""
        read -n 1 -s -rp "  Select an option [0-7, a-g, s]: " choice || true

        case "$choice" in
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
                remove_acpi_fix
                ;;
            5)
                install_overclock
                ;;
            6)
                install_wake_on_lan
                ;;
            7)
                update_cyan-skillfish
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
                echo -e "\n  ${YELLOW}Press any key to return to the menu...${RESET}"
                read -n 1 -s -r || true # Instant return key matching the input engine
                ;;

            r)
                print_info "Reinitializing toolkit memory tracking blocks..."
                sleep 0.5
                
                # FIX: Utilizing exec replaces the running process with a fresh copy of itself on disk.
                # We preserve $SCRIPT_PATH and pass standard arguments down the pipe seamlessly.
                exec bash "$SCRIPT_PATH" "$@"
                ;;
                
            0)
                echo -e "${GREEN}Exiting Bazzite Toolbox. Cleaning environment...${NC}"
                sleep 1

                if [ -n "$PPID" ]; then
                    kill -SIGHUP "$PPID" 2>/dev/null
                fi
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice! Please select a valid number.${NC}"
                sleep 1.5
                ;;
        esac
    done
}

# Start the menu loop execution
show_menu
