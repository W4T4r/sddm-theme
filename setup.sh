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
readonly DEFAULT_FORM_STYLE="blur"
readonly DEFAULT_BACKGROUND="nixos-nineish-dark-gray"
readonly DEFAULT_BACKGROUND_PLACEMENT="fill"
readonly DEFAULT_FONT="Orbitron"
readonly DEFAULT_BACKGROUND_DIM="0.2"
readonly DEFAULT_BACKGROUND_COLOR="#101820"
readonly DEFAULT_FORM_BACKGROUND_COLOR="#80262626"
readonly DEFAULT_TEXT_COLOR="#eeeeee"
readonly DEFAULT_MUTED_TEXT_COLOR="#999999"
readonly DEFAULT_ACCENT_COLOR="#66ccff"
readonly DEFAULT_INPUT_BACKGROUND_COLOR="#20242c"
readonly DEFAULT_BUTTON_BACKGROUND_COLOR="#303846"
readonly DEFAULT_BLUR_AMOUNT="2.4"
readonly DEFAULT_BLUR_MAX="60"
readonly DEFAULT_FORM_WIDTH_RATIO="0.45"
readonly DEFAULT_FONT_SIZE="13"
readonly DEFAULT_ROUND_CORNERS="18"
readonly DEFAULT_CLOCK_FORMAT="24h"
readonly DEFAULT_CLOCK_LOCALE="en_US"
readonly DEFAULT_SYSTEM_BUTTONS_VISIBLE="false"
readonly DEFAULT_VIRTUAL_KEYBOARD_VISIBLE="false"

readonly -a COMPOSITIONS=(
    "center" "left" "right"
)

readonly -a FORM_STYLES=(
    "solid" "blur"
)

readonly -a BACKGROUND_PLACEMENTS=(
    "fill" "fit" "top" "bottom" "left" "right"
    "top-left" "top-right" "bottom-left" "bottom-right"
)

readonly -a FONTS=(
    "Open Sans" "ArcadeClassic" "ESPACION" "Electroharmonix"
    "Fragile Bombers" "Fragile Bombers Attack" "Fragile Bombers Down"
    "KogniGear" "Orbitron" "Pixelon" "Thunderman"
)

readonly -a CLOCK_FORMATS=(
    "24h" "12h" "iso" "locale"
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

input_value() {
    local prompt="$1"
    local default="$2"

    if command -v gum &>/dev/null; then
        gum input --prompt "$prompt " --value "$default"
    else
        local value
        echo -n "$prompt [$default]: "
        read -r value
        echo "${value:-$default}"
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

    if grep -q "^${key}=" "$file"; then
        sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$file"
    else
        printf '%s="%s"\n' "$key" "$value" >> "$file"
    fi
}

number_in_range() {
    local value="$1"
    local min="$2"
    local max="$3"
    local max_inclusive="$4"

    awk -v value="$value" -v min="$min" -v max="$max" -v max_inclusive="$max_inclusive" '
        value !~ /^-?[0-9]+([.][0-9]+)?$/ { exit 1 }
        max_inclusive == "true" && value >= min && value <= max { exit 0 }
        max_inclusive != "true" && value >= min && value < max { exit 0 }
        { exit 1 }
    '
}

number_at_least() {
    local value="$1"
    local min="$2"

    awk -v value="$value" -v min="$min" '
        value !~ /^-?[0-9]+([.][0-9]+)?$/ { exit 1 }
        value >= min { exit 0 }
        { exit 1 }
    '
}

bool_value() {
    local value="$1"

    [[ "$value" == "true" || "$value" == "false" ]]
}

hide_value_from_visible() {
    local value="$1"

    if [[ "$value" == "true" ]]; then
        echo "false"
    else
        echo "true"
    fi
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
            set_conf_value "$file" "FormPosition" "center"
            set_conf_value "$file" "VirtualKeyboardPosition" "center"
            ;;
        left)
            set_conf_value "$file" "FormPosition" "left"
            set_conf_value "$file" "VirtualKeyboardPosition" "left"
            ;;
        right)
            set_conf_value "$file" "FormPosition" "right"
            set_conf_value "$file" "VirtualKeyboardPosition" "right"
            ;;
        *)
            error "Unknown composition: $composition"
            return 1
            ;;
    esac
}

apply_form_style() {
    local file="$1"
    local form_style="$2"

    case "$form_style" in
        solid)
            set_conf_value "$file" "PartialBlur" "false"
            set_conf_value "$file" "FullBlur" ""
            set_conf_value "$file" "HaveFormBackground" "true"
            ;;
        blur)
            set_conf_value "$file" "PartialBlur" "true"
            set_conf_value "$file" "FullBlur" ""
            set_conf_value "$file" "HaveFormBackground" "true"
            ;;
        *)
            error "Unknown form style: $form_style"
            return 1
            ;;
    esac
}

apply_background_placement() {
    local file="$1"
    local background_placement="$2"

    case "$background_placement" in
        fill)
            set_conf_value "$file" "CropBackground" "true"
            set_conf_value "$file" "BackgroundHorizontalAlignment" "center"
            set_conf_value "$file" "BackgroundVerticalAlignment" "center"
            ;;
        fit)
            set_conf_value "$file" "CropBackground" "false"
            set_conf_value "$file" "BackgroundHorizontalAlignment" "center"
            set_conf_value "$file" "BackgroundVerticalAlignment" "center"
            ;;
        top)
            set_conf_value "$file" "CropBackground" "false"
            set_conf_value "$file" "BackgroundHorizontalAlignment" "center"
            set_conf_value "$file" "BackgroundVerticalAlignment" "top"
            ;;
        bottom)
            set_conf_value "$file" "CropBackground" "false"
            set_conf_value "$file" "BackgroundHorizontalAlignment" "center"
            set_conf_value "$file" "BackgroundVerticalAlignment" "bottom"
            ;;
        left)
            set_conf_value "$file" "CropBackground" "false"
            set_conf_value "$file" "BackgroundHorizontalAlignment" "left"
            set_conf_value "$file" "BackgroundVerticalAlignment" "center"
            ;;
        right)
            set_conf_value "$file" "CropBackground" "false"
            set_conf_value "$file" "BackgroundHorizontalAlignment" "right"
            set_conf_value "$file" "BackgroundVerticalAlignment" "center"
            ;;
        top-left)
            set_conf_value "$file" "CropBackground" "false"
            set_conf_value "$file" "BackgroundHorizontalAlignment" "left"
            set_conf_value "$file" "BackgroundVerticalAlignment" "top"
            ;;
        top-right)
            set_conf_value "$file" "CropBackground" "false"
            set_conf_value "$file" "BackgroundHorizontalAlignment" "right"
            set_conf_value "$file" "BackgroundVerticalAlignment" "top"
            ;;
        bottom-left)
            set_conf_value "$file" "CropBackground" "false"
            set_conf_value "$file" "BackgroundHorizontalAlignment" "left"
            set_conf_value "$file" "BackgroundVerticalAlignment" "bottom"
            ;;
        bottom-right)
            set_conf_value "$file" "CropBackground" "false"
            set_conf_value "$file" "BackgroundHorizontalAlignment" "right"
            set_conf_value "$file" "BackgroundVerticalAlignment" "bottom"
            ;;
        *)
            error "Unknown background placement: $background_placement"
            return 1
            ;;
    esac
}

apply_advanced_settings() {
    local file="$1"
    local background_dim="$2"
    local background_color="$3"
    local form_background_color="$4"
    local text_color="$5"
    local muted_text_color="$6"
    local accent_color="$7"
    local input_background_color="$8"
    local button_background_color="$9"
    local blur_amount="${10}"
    local blur_max="${11}"
    local form_width_ratio="${12}"
    local font_size="${13}"
    local round_corners="${14}"
    local clock_format="${15}"
    local clock_locale="${16}"
    local system_buttons_visible="${17}"
    local virtual_keyboard_visible="${18}"

    number_in_range "$background_dim" "0.0" "1.0" "true" || { error "background.dim must be between 0.0 and 1.0"; return 1; }
    number_in_range "$blur_amount" "0.0" "3.0" "false" || { error "form.blur.amount must be at least 0.0 and less than 3.0"; return 1; }
    number_at_least "$blur_max" "2" || { error "form.blur.max must be at least 2"; return 1; }
    number_in_range "$form_width_ratio" "0.0" "1.0" "true" && number_at_least "$form_width_ratio" "0.000001" || { error "form.widthRatio must be greater than 0.0 and at most 1.0"; return 1; }
    number_at_least "$font_size" "0.000001" || { error "font.size must be positive"; return 1; }
    number_at_least "$round_corners" "0" || { error "roundCorners must be at least 0"; return 1; }
    bool_value "$system_buttons_visible" || { error "systemButtons.visible must be true or false"; return 1; }
    bool_value "$virtual_keyboard_visible" || { error "virtualKeyboard.visible must be true or false"; return 1; }

    set_conf_value "$file" "DimBackground" "$background_dim"
    set_conf_value "$file" "BackgroundColor" "$background_color"
    set_conf_value "$file" "DimBackgroundColor" "$background_color"
    set_conf_value "$file" "FormBackgroundColor" "$form_background_color"
    set_conf_value "$file" "HeaderTextColor" "$text_color"
    set_conf_value "$file" "DateTextColor" "$text_color"
    set_conf_value "$file" "TimeTextColor" "$text_color"
    set_conf_value "$file" "LoginFieldTextColor" "$text_color"
    set_conf_value "$file" "PasswordFieldTextColor" "$text_color"
    set_conf_value "$file" "LoginButtonTextColor" "$text_color"
    set_conf_value "$file" "SystemButtonsIconsColor" "$text_color"
    set_conf_value "$file" "SessionButtonTextColor" "$text_color"
    set_conf_value "$file" "VirtualKeyboardButtonTextColor" "$text_color"
    set_conf_value "$file" "DropdownTextColor" "$text_color"
    set_conf_value "$file" "UserIconColor" "$text_color"
    set_conf_value "$file" "PasswordIconColor" "$text_color"
    set_conf_value "$file" "PlaceholderTextColor" "$muted_text_color"
    set_conf_value "$file" "HighlightTextColor" "$muted_text_color"
    set_conf_value "$file" "HoverUserIconColor" "$accent_color"
    set_conf_value "$file" "HoverPasswordIconColor" "$accent_color"
    set_conf_value "$file" "HoverSystemButtonsIconsColor" "$accent_color"
    set_conf_value "$file" "HoverSessionButtonTextColor" "$accent_color"
    set_conf_value "$file" "HoverVirtualKeyboardButtonTextColor" "$accent_color"
    set_conf_value "$file" "LoginFieldBackgroundColor" "$input_background_color"
    set_conf_value "$file" "PasswordFieldBackgroundColor" "$input_background_color"
    set_conf_value "$file" "DropdownBackgroundColor" "$input_background_color"
    set_conf_value "$file" "LoginButtonBackgroundColor" "$button_background_color"
    set_conf_value "$file" "DropdownSelectedBackgroundColor" "$button_background_color"
    set_conf_value "$file" "HighlightBackgroundColor" "$button_background_color"
    set_conf_value "$file" "HighlightBorderColor" "$button_background_color"
    set_conf_value "$file" "WarningColor" "$button_background_color"
    set_conf_value "$file" "Blur" "$blur_amount"
    set_conf_value "$file" "BlurMax" "$blur_max"
    set_conf_value "$file" "FormWidthRatio" "$form_width_ratio"
    set_conf_value "$file" "FontSize" "$font_size"
    set_conf_value "$file" "RoundCorners" "$round_corners"
    set_conf_value "$file" "Locale" "$clock_locale"
    set_conf_value "$file" "HideSystemButtons" "$(hide_value_from_visible "$system_buttons_visible")"
    set_conf_value "$file" "HideVirtualKeyboard" "$(hide_value_from_visible "$virtual_keyboard_visible")"

    case "$clock_format" in
        24h)
            set_conf_value "$file" "HourFormat" "HH:mm"
            set_conf_value "$file" "DateFormat" "dddd d MMMM"
            ;;
        12h)
            set_conf_value "$file" "HourFormat" "h:mm AP"
            set_conf_value "$file" "DateFormat" "dddd d MMMM"
            ;;
        iso)
            set_conf_value "$file" "HourFormat" "HH:mm"
            set_conf_value "$file" "DateFormat" "yyyy-MM-dd"
            ;;
        locale)
            set_conf_value "$file" "HourFormat" ""
            set_conf_value "$file" "DateFormat" ""
            ;;
        *) error "Unknown clock format: $clock_format"; return 1 ;;
    esac
}

write_selected_theme() {
    local theme_root="$1"
    local composition="$2"
    local background="$3"
    local form_style="$4"
    local background_placement="$5"
    local font="$6"
    local background_dim="$7"
    local background_color="$8"
    local form_background_color="$9"
    local text_color="${10}"
    local muted_text_color="${11}"
    local accent_color="${12}"
    local input_background_color="${13}"
    local button_background_color="${14}"
    local blur_amount="${15}"
    local blur_max="${16}"
    local form_width_ratio="${17}"
    local font_size="${18}"
    local round_corners="${19}"
    local clock_format="${20}"
    local clock_locale="${21}"
    local system_buttons_visible="${22}"
    local virtual_keyboard_visible="${23}"
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
    set_conf_value "$tmp" "Font" "$font"
    apply_composition "$tmp" "$composition"
    apply_form_style "$tmp" "$form_style"
    apply_background_placement "$tmp" "$background_placement"
    apply_advanced_settings "$tmp" "$background_dim" "$background_color" "$form_background_color" "$text_color" "$muted_text_color" "$accent_color" "$input_background_color" "$button_background_color" "$blur_amount" "$blur_max" "$form_width_ratio" "$font_size" "$round_corners" "$clock_format" "$clock_locale" "$system_buttons_visible" "$virtual_keyboard_visible"

    sudo install -m 0644 "$tmp" "$output"
    rm -f "$tmp"

    sudo sed -i \
        -e "s|^ConfigFile=.*|ConfigFile=Themes/selected.conf|" \
        -e "s|^Screenshot=.*|Screenshot=${screenshot}|" \
        "$METADATA"
}

# Select theme composition, form style, background, placement, and font
select_theme() {
    [[ ! -f "$METADATA" ]] && { error "Install theme first"; return 1; }

    local composition
    local background
    local form_style
    local background_placement
    local font
    local background_dim="$DEFAULT_BACKGROUND_DIM"
    local background_color="$DEFAULT_BACKGROUND_COLOR"
    local form_background_color="$DEFAULT_FORM_BACKGROUND_COLOR"
    local text_color="$DEFAULT_TEXT_COLOR"
    local muted_text_color="$DEFAULT_MUTED_TEXT_COLOR"
    local accent_color="$DEFAULT_ACCENT_COLOR"
    local input_background_color="$DEFAULT_INPUT_BACKGROUND_COLOR"
    local button_background_color="$DEFAULT_BUTTON_BACKGROUND_COLOR"
    local blur_amount="$DEFAULT_BLUR_AMOUNT"
    local blur_max="$DEFAULT_BLUR_MAX"
    local form_width_ratio="$DEFAULT_FORM_WIDTH_RATIO"
    local font_size="$DEFAULT_FONT_SIZE"
    local round_corners="$DEFAULT_ROUND_CORNERS"
    local clock_format="$DEFAULT_CLOCK_FORMAT"
    local clock_locale="$DEFAULT_CLOCK_LOCALE"
    local system_buttons_visible="$DEFAULT_SYSTEM_BUTTONS_VISIBLE"
    local virtual_keyboard_visible="$DEFAULT_VIRTUAL_KEYBOARD_VISIBLE"
    local -a backgrounds

    composition=$(choose "${COMPOSITIONS[@]}" || echo "$DEFAULT_COMPOSITION")
    form_style=$(choose "${FORM_STYLES[@]}" || echo "$DEFAULT_FORM_STYLE")
    mapfile -t backgrounds < <(list_backgrounds "$THEMES_DIR/$THEME_NAME")
    [[ ${#backgrounds[@]} -eq 0 ]] && { error "No supported backgrounds found"; return 1; }
    background=$(choose "${backgrounds[@]}" || echo "$DEFAULT_BACKGROUND")
    background_placement=$(choose "${BACKGROUND_PLACEMENTS[@]}" || echo "$DEFAULT_BACKGROUND_PLACEMENT")
    font=$(choose "${FONTS[@]}" || echo "$DEFAULT_FONT")

    if confirm "Configure advanced options?"; then
        background_dim=$(input_value "background.dim" "$DEFAULT_BACKGROUND_DIM")
        background_color=$(input_value "background.color" "$DEFAULT_BACKGROUND_COLOR")
        form_background_color=$(input_value "form.background.color" "$DEFAULT_FORM_BACKGROUND_COLOR")
        text_color=$(input_value "colors.text" "$DEFAULT_TEXT_COLOR")
        muted_text_color=$(input_value "colors.mutedText" "$DEFAULT_MUTED_TEXT_COLOR")
        accent_color=$(input_value "colors.accent" "$DEFAULT_ACCENT_COLOR")
        input_background_color=$(input_value "colors.input.background" "$DEFAULT_INPUT_BACKGROUND_COLOR")
        button_background_color=$(input_value "colors.button.background" "$DEFAULT_BUTTON_BACKGROUND_COLOR")
        blur_amount=$(input_value "form.blur.amount" "$DEFAULT_BLUR_AMOUNT")
        blur_max=$(input_value "form.blur.max" "$DEFAULT_BLUR_MAX")
        form_width_ratio=$(input_value "form.widthRatio" "$DEFAULT_FORM_WIDTH_RATIO")
        font_size=$(input_value "font.size" "$DEFAULT_FONT_SIZE")
        round_corners=$(input_value "roundCorners" "$DEFAULT_ROUND_CORNERS")
        system_buttons_visible=$(input_value "systemButtons.visible" "$DEFAULT_SYSTEM_BUTTONS_VISIBLE")
        virtual_keyboard_visible=$(input_value "virtualKeyboard.visible" "$DEFAULT_VIRTUAL_KEYBOARD_VISIBLE")
        clock_format=$(choose "${CLOCK_FORMATS[@]}" || echo "$DEFAULT_CLOCK_FORMAT")
        clock_locale=$(input_value "clock.locale" "$DEFAULT_CLOCK_LOCALE")
    fi

    write_selected_theme "$THEMES_DIR/$THEME_NAME" "$composition" "$background" "$form_style" "$background_placement" "$font" "$background_dim" "$background_color" "$form_background_color" "$text_color" "$muted_text_color" "$accent_color" "$input_background_color" "$button_background_color" "$blur_amount" "$blur_max" "$form_width_ratio" "$font_size" "$round_corners" "$clock_format" "$clock_locale" "$system_buttons_visible" "$virtual_keyboard_visible"
    info "Selected composition: $composition"
    info "Selected form style: $form_style"
    info "Selected background: $background"
    info "Selected background placement: $background_placement"
    info "Selected font: $font"
    info "Selected background dim: $background_dim"
    info "Selected background color: $background_color"
    info "Selected form background color: $form_background_color"
    info "Selected text color: $text_color"
    info "Selected muted text color: $muted_text_color"
    info "Selected accent color: $accent_color"
    info "Selected input background color: $input_background_color"
    info "Selected button background color: $button_background_color"
    info "Selected blur amount: $blur_amount"
    info "Selected blur max: $blur_max"
    info "Selected form width ratio: $form_width_ratio"
    info "Selected font size: $font_size"
    info "Selected round corners: $round_corners"
    info "Selected clock format: $clock_format"
    info "Selected clock locale: $clock_locale"
    info "Selected system buttons visible: $system_buttons_visible"
    info "Selected virtual keyboard visible: $virtual_keyboard_visible"
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
            "🎨 Select Theme Options" \
            "✨ Preview the set theme" \
            "❌ Exit")

        case "$choice" in
            "🚀 Complete Installation (recommended)") install_deps && clone_repo && install_theme && select_theme && enable_sddm && info "Everything done!" && exit 0;;
            "📦 Install Dependencies") install_deps ;;
            "📥 Clone Repository") clone_repo ;;
            "📂 Install Theme") install_theme ;;
            "🔧 Enable SDDM Service") enable_sddm ;;
            "🎨 Select Theme Options") select_theme ;;
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
