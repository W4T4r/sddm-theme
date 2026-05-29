#!/bin/bash

## SDDM Theme Installer
## Based on sddm-astronaut-theme by Keyitdev https://github.com/Keyitdev/sddm-astronaut-theme
## Copyright (C) 2022-2025 Keyitdev

# Script works in Arch, Fedora, Ubuntu. Didn't tried in Void and openSUSE

set -euo pipefail

readonly THEME_REPO="https://github.com/W4T4r/sddm-theme.git"
readonly THEME_NAME="sddm-theme"
readonly THEMES_DIR="/usr/share/sddm/themes"
readonly PATH_TO_GIT_CLONE="$HOME/$THEME_NAME"
readonly METADATA="$THEMES_DIR/$THEME_NAME/metadata.desktop"
readonly DATE=$(date +%s)

readonly DEFAULT_COMPOSITION="center"
readonly DEFAULT_BACKGROUND="nixos-gear"

readonly -a COMPOSITIONS=(
    "center" "left" "right"
)

readonly -a SUPPORTED_BACKGROUND_EXTENSIONS=(
    "png" "jpg" "jpeg" "webp" "gif" "avi" "mp4" "mov" "mkv" "m4v" "webm"
)

# Logging with gum fallback
info() {
    if command -v gum &>/dev/null; then
        gum style --foreground 10 "✅ $*"
    else
        echo -e "\e[32m✅ $*\e[0m"
    fi
}

warn() {
    if command -v gum &>/dev/null; then
        gum style --foreground 11 "⚠  $*"
    else
        echo -e "\e[33m⚠  $*\e[0m"
    fi
}

error() {
    if command -v gum &>/dev/null; then
        gum style --foreground 9 "❌ $*" >&2
    else
        echo -e "\e[31m❌ $*\e[0m" >&2
    fi
}

# UI functions
confirm() {
    if command -v gum &>/dev/null; then
        gum confirm "$1"
    else
        echo -n "$1 (y/n): "; read -r r; [[ "$r" =~ ^[Yy]$ ]]
    fi
}

choose() {
    if command -v gum &>/dev/null; then
        gum choose --cursor.foreground 12 --header="" --header.foreground 12 "$@"
    else
        select opt in "$@"; do [[ -n "$opt" ]] && { echo "$opt"; break; }; done
    fi
}

spin() {
    local title="$1"; shift
    if command -v gum &>/dev/null; then
        gum spin --spinner="dot" --title="$title" -- "$@"
    else
        echo "$title"; "$@"
    fi
}

# Install gum if missing
install_gum() {
    local mgr=$(for m in pacman xbps-install dnf zypper apt; do command -v $m &>/dev/null && { echo $m; break; }; done)

    case $mgr in
        pacman) sudo pacman -S gum ;;
        dnf) sudo dnf install -y gum ;;
        zypper) sudo zypper install -y gum ;;
        xbps-install) sudo xbps-install -y gum ;;
        # refrence https://github.com/basecamp/omakub/issues/222
        apt)
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
            echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
            sudo apt update && sudo apt install -y gum ;;
        *) error "Cannot install gum automatically"; return 1 ;;
    esac
}

# Check and install gum
check_gum() {
    if ! command -v gum &>/dev/null; then
        warn "Gum was not found - provides better UI experience"
        if confirm "Install gum?"; then
            install_gum && { info "Restarting with gum..."; main; } || warn "Using fallback UI"
        fi
    fi
}

# Install dependencies
install_deps() {
    local mgr=$(for m in pacman xbps-install dnf zypper apt; do command -v $m &>/dev/null && { echo $m; break; }; done)
    info "Package manager: $mgr"

    case $mgr in
        pacman) sudo pacman --needed -S sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg ;;
        xbps-install) sudo xbps-install -y sddm qt6-svg qt6-virtualkeyboard qt6-multimedia ;;
        dnf) sudo dnf install -y sddm qt6-qtsvg qt6-qtvirtualkeyboard qt6-qtmultimedia ;;
        zypper) sudo zypper install -y sddm libQt6Svg6 qt6-virtualkeyboard qt6-multimedia ;;
        apt) sudo apt update && sudo apt install -y sddm qt6-svg-dev qml6-module-qtquick-virtualkeyboard qt6-multimedia-dev ;;
        *) error "Unsupported package manager"; return 1 ;;
    esac
    info "Dependencies installed"
}

# Clone repository
clone_repo() {
    [[ -d "$PATH_TO_GIT_CLONE" ]] && mv "$PATH_TO_GIT_CLONE" "${PATH_TO_GIT_CLONE}_$DATE"
    spin "Cloning repository..." git clone -b master --depth 1 "$THEME_REPO" "$PATH_TO_GIT_CLONE"
    info "Repository cloned to $PATH_TO_GIT_CLONE"
}

# Install theme
install_theme() {
    local src="$HOME/$THEME_NAME"
    local dst="$THEMES_DIR/$THEME_NAME"

    [[ ! -d "$src" ]] && { error "Clone repository first"; return 1;}

    # Backup and copy
    [[ -d "$dst" ]] && sudo mv "$dst" "${dst}_$DATE"
    sudo mkdir -p "$dst"
    spin "Installing theme files..." sudo cp -r "$src"/* "$dst"/

    # Install fonts
    [[ -d "$dst/Fonts" ]] && spin "Installing fonts..." sudo cp -r "$dst/Fonts"/* /usr/share/fonts/

    # Configure SDDM
    echo "[Theme]
    Current=$THEME_NAME" | sudo tee /etc/sddm.conf >/dev/null

    sudo mkdir -p /etc/sddm.conf.d
    echo "[General]
    InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf >/dev/null

    info "Theme installed"
}

# Config helpers
set_conf_value() {
    local file="$1"
    local key="$2"
    local value="$3"

    sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$file"
}

is_supported_background_file() {
    local file="$1"
    local name
    local ext

    name=$(basename "$file")
    ext="${name##*.}"
    [[ "$name" == "$ext" ]] && return 1
    ext="${ext,,}"

    for supported in "${SUPPORTED_BACKGROUND_EXTENSIONS[@]}"; do
        [[ "$ext" == "$supported" ]] && return 0
    done

    return 1
}

background_id_from_file() {
    local name
    name=$(basename "$1")
    echo "${name%.*}"
}

list_backgrounds() {
    local theme_root="$1"
    local file

    [[ ! -d "$theme_root/Backgrounds" ]] && return 0

    while IFS= read -r -d '' file; do
        is_supported_background_file "$file" && background_id_from_file "$file"
    done < <(find "$theme_root/Backgrounds" -maxdepth 1 -type f -print0) | sort -u
}

background_file_for_id() {
    local theme_root="$1"
    local background="$2"
    local file

    [[ ! -d "$theme_root/Backgrounds" ]] && return 1

    while IFS= read -r -d '' file; do
        if is_supported_background_file "$file" && [[ "$(background_id_from_file "$file")" == "$background" ]]; then
            echo "$file"
            return 0
        fi
    done < <(find "$theme_root/Backgrounds" -maxdepth 1 -type f -print0)

    return 1
}

metadata_screenshot_for_background() {
    local theme_root="$1"
    local background="$2"
    local background_path="$3"
    local ext="${background_path##*.}"

    ext="${ext,,}"

    if [[ -f "$theme_root/Previews/${background}.png" ]]; then
        echo "Previews/${background}.png"
    elif [[ "$ext" == "png" || "$ext" == "jpg" || "$ext" == "jpeg" || "$ext" == "webp" ]]; then
        echo "$background_path"
    else
        echo "Previews/${DEFAULT_BACKGROUND}.png"
    fi
}

apply_composition() {
    local file="$1"
    local composition="$2"

    case "$composition" in
        center)
            set_conf_value "$file" "PartialBlur" "true"
            set_conf_value "$file" "FullBlur" ""
            set_conf_value "$file" "HaveFormBackground" "false"
            set_conf_value "$file" "FormPosition" "center"
            set_conf_value "$file" "VirtualKeyboardPosition" "center"
            ;;
        left)
            set_conf_value "$file" "PartialBlur" "false"
            set_conf_value "$file" "FullBlur" ""
            set_conf_value "$file" "HaveFormBackground" "true"
            set_conf_value "$file" "FormPosition" "left"
            set_conf_value "$file" "VirtualKeyboardPosition" "left"
            ;;
        right)
            set_conf_value "$file" "PartialBlur" "false"
            set_conf_value "$file" "FullBlur" ""
            set_conf_value "$file" "HaveFormBackground" "true"
            set_conf_value "$file" "FormPosition" "right"
            set_conf_value "$file" "VirtualKeyboardPosition" "right"
            ;;
        *)
            error "Unknown composition: $composition"
            return 1
            ;;
    esac
}

write_selected_theme() {
    local theme_root="$1"
    local composition="$2"
    local background="$3"
    local template="$theme_root/Themes/${DEFAULT_BACKGROUND}.conf"
    local output="$theme_root/Themes/selected.conf"
    local background_file
    local background_path
    local screenshot
    local tmp

    [[ ! -f "$template" ]] && { error "Template config not found: $template"; return 1; }
    background_file=$(background_file_for_id "$theme_root" "$background") || { error "Background not found: $background"; return 1; }
    background_path="${background_file#"$theme_root"/}"
    screenshot=$(metadata_screenshot_for_background "$theme_root" "$background" "$background_path")

    tmp=$(mktemp)
    cp "$template" "$tmp"

    set_conf_value "$tmp" "Background" "$background_path"
    apply_composition "$tmp" "$composition"

    sudo install -m 0644 "$tmp" "$output"
    rm -f "$tmp"

    sudo sed -i \
        -e "s|^ConfigFile=.*|ConfigFile=Themes/selected.conf|" \
        -e "s|^Screenshot=.*|Screenshot=${screenshot}|" \
        "$METADATA"
}

# Select theme composition and background
select_theme() {
    [[ ! -f "$METADATA" ]] && { error "Install theme first"; return 1; }

    local composition
    local background
    local -a backgrounds

    composition=$(choose "${COMPOSITIONS[@]}" || echo "$DEFAULT_COMPOSITION")
    mapfile -t backgrounds < <(list_backgrounds "$THEMES_DIR/$THEME_NAME")
    [[ ${#backgrounds[@]} -eq 0 ]] && { error "No supported backgrounds found"; return 1; }
    background=$(choose "${backgrounds[@]}" || echo "$DEFAULT_BACKGROUND")

    write_selected_theme "$THEMES_DIR/$THEME_NAME" "$composition" "$background"
    info "Selected composition: $composition"
    info "Selected background: $background"
}

_disable_dm_systemd() {
    sudo systemctl disable display-manager.service 2>/dev/null || true
}
_disable_dm_openrc() {
    for dm in gdm lightdm lxdm emptty greetd; do
        sudo rc-update del "$dm" default 2>/dev/null || true
    done
}
_disable_dm_runit() {
    local runsvdir
    runsvdir=$(_runit_runsvdir)
    for dm in gdm lightdm lxdm emptty greetd; do
        sudo rm -f "$runsvdir/$dm" 2>/dev/null || true
    done
}
_disable_dm_dinit() {
    for dm in gdm lightdm lxdm emptty greetd; do
        sudo rm -f "/etc/dinit.d/boot.d/$dm" 2>/dev/null || true
        sudo dinitctl disable "$dm" 2>/dev/null || true
    done
}

_runit_runsvdir() {
    if   [ -d /run/runit/service ];          then echo "/run/runit/service"
    elif [ -d /etc/runit/runsvdir/default ]; then echo "/etc/runit/runsvdir/default"
    else
        error "Cannot find runit service directory"
        return 1
    fi
}

detect_init() {
    # Pass 1: PID 1 comm (most reliable - no external deps)
    local pid1_comm
    pid1_comm=$(cat /proc/1/comm 2>/dev/null || true)
    case "$pid1_comm" in
        systemd)    echo "systemd";  return ;;
        dinit)      echo "dinit";    return ;;
        runit)      echo "runit";    return ;;
        openrc-init|openrc) echo "openrc"; return ;;
    esac

    # Pass 2: characteristic binaries / directories
    command -v dinitctl      &>/dev/null && { echo "dinit";   return; }
    command -v rc-service    &>/dev/null && { echo "openrc";  return; }
    { command -v sv &>/dev/null && [ -d /etc/sv ]; } && { echo "runit"; return; }
    command -v systemctl     &>/dev/null && { echo "systemd"; return; }

    echo "unknown"
}

# Enable SDDM
enable_sddm() {
    local init
    init=$(detect_init)
    info "Detected init system: $init"

    case "$init" in
        systemd)
            _disable_dm_systemd
            sudo systemctl enable --now sddm.service
            ;;

        openrc)
            _disable_dm_openrc
            sudo rc-update add sddm default
            # Start immediately if we are in a live session
            sudo rc-service sddm start 2>/dev/null || true
            ;;

        runit)
            local runsvdir
            runsvdir=$(_runit_runsvdir)

            if [ ! -d /etc/sv/sddm ]; then
                error "/etc/sv/sddm not found - is sddm-runit (or equivalent) installed?"
                return 1
            fi

            _disable_dm_runit
            sudo ln -sf /etc/sv/sddm "$runsvdir/sddm"
            info "sddm symlinked into $runsvdir"
            ;;

        dinit)
            if [ ! -f /etc/dinit.d/sddm ]; then
                error "/etc/dinit.d/sddm not found - is sddm-dinit (or equivalent) installed?"
                return 1
            fi

            _disable_dm_dinit
            # boot.d symlink makes the service start automatically at boot
            sudo mkdir -p /etc/dinit.d/boot.d
            sudo ln -sf /etc/dinit.d/sddm /etc/dinit.d/boot.d/sddm

            # Also enable & start in the running session
            if command -v dinitctl &>/dev/null; then
                sudo dinitctl enable sddm  2>/dev/null || true
                sudo dinitctl start  sddm  2>/dev/null || true
            fi
            ;;

        # ── Unknown / manual fallback ─────────────────────
        *)
            warn "Could not detect init system automatically."
            warn "Please enable sddm manually:"
            echo ""
            echo "  systemd  -  sudo systemctl enable --now sddm"
            echo "  openrc   -  sudo rc-update add sddm default"
            echo "  runit    -  sudo ln -s /etc/sv/sddm /run/runit/service/"
            echo "  dinit    -  sudo ln -s /etc/dinit.d/sddm /etc/dinit.d/boot.d/sddm"
            return 1
            ;;
    esac

    info "SDDM enabled"
    warn "Reboot required"
}

preview_theme(){
    local log_file="/tmp/${THEME_NAME}_$DATE.txt"
    
    sddm-greeter-qt6 --test-mode --theme "$THEMES_DIR/$THEME_NAME/" > "$log_file" 2>&1 &
    greeter_pid=$!

    # wait for ten seconds
    for i in {1..10}; do
        if ! kill -0 "$greeter_pid" 2>/dev/null; then
            break
        fi
        sleep 1
    done

    if kill -0 "$greeter_pid" 2>/dev/null; then
        kill "$greeter_pid"
    fi


    local theme="$(sed -n 's|^ConfigFile=Themes/\(.*\)\.conf|\1|p' "$METADATA")"
    info "Preview closed ($theme config found)."
    info "Log file: $log_file"
}

# Main menu
main() {
    [[ $EUID -eq 0 ]] && { error "Don't run as root"; exit 1; }
    command -v git &>/dev/null || { error "git required"; exit 1; }

    check_gum
    clear
    while true; do
        if command -v gum &>/dev/null; then
            gum style --bold --padding "0 2" --border double --border-foreground 12 "SDDM Theme Installer"
        else
            echo -e "\e[36mSDDM Theme Installer\e[0m"
        fi

        local choice=$(choose \
            "🚀 Complete Installation (recommended)" \
            "📦 Install Dependencies" \
            "📥 Clone Repository" \
            "📂 Install Theme" \
            "🔧 Enable SDDM Service" \
            "🎨 Select Composition and Background" \
            "✨ Preview the set theme" \
            "❌ Exit")

        case "$choice" in
            "🚀 Complete Installation (recommended)") install_deps && clone_repo && install_theme && select_theme && enable_sddm && info "Everything done!" && exit 0;;
            "📦 Install Dependencies") install_deps ;;
            "📥 Clone Repository") clone_repo ;;
            "📂 Install Theme") install_theme ;;
            "🔧 Enable SDDM Service") enable_sddm ;;
            "🎨 Select Composition and Background") select_theme ;;
            "✨ Preview the set theme") preview_theme;;
            "❌ Exit") info "Goodbye!"; exit 0 ;;
        esac

        echo; if command -v gum &>/dev/null; then
            gum input --placeholder="Press Enter to continue..."
        else
            echo -n "Press Enter to continue..."; read -r
        fi
    done
}

# trap 'echo; info "Cancelled"; exit 130' INT TERM
main "$@"
