# =============================================================================
# larp.OS - Kickstart (Fedora live ISO)
# Hyprland (Wayland) + gaming/performance, Catppuccin Mocha, es_MX / latam
# Build with:  ./build-iso.sh   (livecd-creator, host Fedora 44)
# Validate with:  ksvalidator larp-fedora.ks
# =============================================================================

# --- Language, keyboard & timezone --------------------------------------------
lang es_MX.UTF-8
keyboard --vckeymap=latam --xlayouts='latam'
timezone America/Mazatlan --utc

# --- Network, firewall, security ----------------------------------------------
network --bootproto=dhcp --device=link --activate
# SSH NO se abre: el usuario live tiene contrasena conocida.
firewall --enabled
selinux --enforcing

# --- Users --------------------------------------------------------------------
rootpw --lock
user --name=larp --groups=wheel --shell=/bin/bash --plaintext --password=larp

# --- Disk (tamano del rootfs de la ISO live; el instalador particiona luego) ---
zerombr
clearpart --all --initlabel
part / --fstype="ext4" --size=12288

# --- Services -----------------------------------------------------------------
services --enabled=NetworkManager,bluetooth,power-profiles-daemon,sddm --disabled=sshd

# --- Repositories (Fedora + RPM Fusion Free/Nonfree + COPR de Hyprland) -------
# $releasever / $basearch los rellena livecd-creator (--releasever=44)
repo --name=fedora --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch
repo --name=rpmfusion-free --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-$releasever&arch=$basearch
repo --name=rpmfusion-free-updates --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-$releasever&arch=$basearch
repo --name=rpmfusion-nonfree --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-$releasever&arch=$basearch
repo --name=rpmfusion-nonfree-updates --mirrorlist=https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-released-$releasever&arch=$basearch
# Hyprland NO esta en los repos oficiales de Fedora: viene de este COPR
repo --name=hyprland-copr --baseurl=https://download.copr.fedorainfracloud.org/results/ashbuk/Hyprland-Fedora/fedora-$releasever-$basearch/

# --- Packages -----------------------------------------------------------------
%packages
@core
@base-x
@hardware-support
@multimedia
@networkmanager-submodules
@anaconda-tools

# Base de ISO live (arranque BIOS + UEFI)
kernel
kernel-modules
kernel-modules-extra
dracut-live
dracut-config-generic
syslinux
memtest86+
grub2-efi-x64
grub2-efi-x64-cdboot
shim-x64
anaconda-live
glibc-langpack-es
glibc-langpack-en
langpacks-es

# Repos de RPM Fusion en el sistema instalado
rpmfusion-free-release
rpmfusion-nonfree-release

# Codecs y aceleracion de video (RPM Fusion)
mesa-va-drivers-freeworld
mesa-vdpau-drivers-freeworld
gstreamer1-plugins-bad-freeworld
gstreamer1-plugin-libav

# Login manager (SDDM con greeter X11 -> por eso @base-x)
sddm

# Hyprland y ecosistema Wayland
hyprland
hyprlock
hypridle
xdg-desktop-portal-hyprland
xdg-desktop-portal-gtk
waybar
rofi
SwayNotificationCenter
swaybg
kitty
thunar
gvfs
qt5ct
qt6ct
qt5-qtwayland
qt6-qtwayland
papirus-icon-theme
pipewire
pipewire-pulseaudio
wireplumber
network-manager-applet
nm-connection-editor
blueman
pavucontrol
brightnessctl
playerctl
grim
slurp
wl-clipboard
mate-polkit
xdg-user-dirs

# Fuentes
jetbrains-mono-fonts
fontawesome-fonts
google-noto-emoji-fonts

# Rendimiento, gaming y utilidades
gamemode
gamescope
btop
fastfetch
flatpak
firefox
curl
wget
git
unzip
tar
rsync
power-profiles-daemon
%end

# --- Post-installation --------------------------------------------------------
%post --log=/root/larp-post-install.log
echo "[+] larp.OS post-install..."

# 1. DNF mas rapido
cat << 'DNFCFG' >> /etc/dnf/dnf.conf
max_parallel_downloads=10
fastestmirror=True
DNFCFG

# 2. Arrancar en modo grafico
systemctl set-default graphical.target

# 3. Flathub (no debe romper el build si falla en chroot)
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# 4. sudo sin contrasena para wheel (solo apropiado para ISO live/demo)
echo "larp ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/larp
chmod 0440 /etc/sudoers.d/larp

# 5. Estructura de configuracion en /etc/skel
SKEL_CONFIG="/etc/skel/.config"
mkdir -p "${SKEL_CONFIG}"/{hypr,waybar,rofi,swaync,kitty,gtk-3.0,gtk-4.0}

# --- 6. Hyprland (hyprland.conf) ---------------------------------------------
cat << 'EOF' > "${SKEL_CONFIG}/hypr/hyprland.conf"
# larp.OS - Hyprland (Catppuccin Mocha)

monitor = , preferred, auto, 1

$mainMod = SUPER

env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = QT_QPA_PLATFORM,wayland;xcb
env = QT_QPA_PLATFORMTHEME,qt6ct
env = XCURSOR_SIZE,24

# Autostart
exec-once = swaybg -c 1e1e2e
exec-once = waybar
exec-once = swaync
exec-once = hypridle
exec-once = nm-applet --indicator
exec-once = blueman-applet
exec-once = /usr/libexec/polkit-mate-authentication-agent-1

input {
    kb_layout = latam
    follow_mouse = 1
    touchpad {
        natural_scroll = true
    }
}

general {
    gaps_in = 6
    gaps_out = 12
    border_size = 2
    col.active_border = rgb(cba6f7) rgb(89b4fa) 45deg
    col.inactive_border = rgb(313244)
    layout = dwindle
}

decoration {
    rounding = 14
    blur {
        enabled = true
        size = 8
        passes = 3
        vibrancy = 0.1696
    }
    shadow {
        enabled = true
        range = 12
        render_power = 3
        color = rgba(11111b66)
    }
}

animations {
    enabled = true
    bezier = easeOutQuint, 0.23, 1, 0.32, 1
    animation = windows, 1, 3, easeOutQuint
    animation = windowsOut, 1, 3, default, popin 80%
    animation = border, 1, 5, default
    animation = fade, 1, 2, default
    animation = workspaces, 1, 3, default
}

dwindle {
    pseudotile = true
    preserve_split = true
}

gesture = 3, horizontal, workspace

misc {
    disable_hyprland_logo = true
    force_default_wallpaper = 0
}

# Apps
bind = $mainMod, Return, exec, kitty
bind = $mainMod, E, exec, thunar
bind = $mainMod, D, exec, rofi -show drun
bind = $mainMod, Space, exec, rofi -show drun
bind = $mainMod, P, exec, swaync-client -t -sw
bind = $mainMod SHIFT, L, exec, hyprlock
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy

# Ventanas
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, V, togglefloating,
bind = $mainMod, F, fullscreen,
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Foco (vim keys)
bind = $mainMod, h, movefocus, l
bind = $mainMod, l, movefocus, r
bind = $mainMod, k, movefocus, u
bind = $mainMod, j, movefocus, d

# Workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5

# Multimedia y brillo
bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindl  = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
bindl  = , XF86AudioPlay, exec, playerctl play-pause
bindl  = , XF86AudioNext, exec, playerctl next
bindl  = , XF86AudioPrev, exec, playerctl previous
EOF

# --- 6b. hypridle / hyprlock --------------------------------------------------
cat << 'EOF' > "${SKEL_CONFIG}/hypr/hypridle.conf"
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

listener {
    timeout = 300
    on-timeout = loginctl lock-session
}

listener {
    timeout = 330
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}

listener {
    timeout = 900
    on-timeout = systemctl suspend
}
EOF

cat << 'EOF' > "${SKEL_CONFIG}/hypr/hyprlock.conf"
general {
    hide_cursor = true
}

background {
    monitor =
    color = rgb(30, 30, 46)
}

input-field {
    monitor =
    size = 300, 50
    outline_thickness = 2
    outer_color = rgb(203, 166, 247)
    inner_color = rgb(49, 50, 68)
    font_color = rgb(205, 214, 244)
    placeholder_text = Contraseña
    position = 0, -20
    halign = center
    valign = center
}
EOF

# --- 7. Waybar (config.jsonc) -------------------------------------------------
# Iconos como escapes \uXXXX de Font Awesome (paquete fontawesome-fonts)
cat << 'EOF' > "${SKEL_CONFIG}/waybar/config.jsonc"
{
    "layer": "top",
    "position": "top",
    "height": 36,
    "margin-top": 8,
    "margin-left": 12,
    "margin-right": 12,
    "spacing": 8,
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["mpris"],
    "modules-right": ["tray", "pulseaudio", "network", "battery", "clock", "custom/power"],

    "hyprland/workspaces": {
        "format": "{id}",
        "on-click": "activate"
    },
    "hyprland/window": {
        "max-length": 40,
        "format": "{}"
    },
    "mpris": {
        "format": "{player_icon} {artist} - {title}",
        "format-paused": "{status_icon} <i>{artist} - {title}</i>",
        "player-icons": {
            "default": "\uf04b"
        },
        "status-icons": {
            "paused": "\uf04c"
        }
    },
    "tray": {
        "icon-size": 18,
        "spacing": 10
    },
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-bluetooth": "\uf025 {volume}%",
        "format-muted": "\uf026",
        "format-icons": {
            "headphone": "\uf025",
            "headset": "\uf025",
            "default": ["\uf027", "\uf027", "\uf028"]
        },
        "on-click": "pavucontrol"
    },
    "network": {
        "format-wifi": "\uf1eb {essid}",
        "format-ethernet": "\uf0e8 Cable",
        "format-disconnected": "\uf071 Sin red",
        "on-click": "nm-connection-editor"
    },
    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-icons": ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"]
    },
    "clock": {
        "format": "\uf017 {:%H:%M}",
        "format-alt": "\uf073 {:%d/%m/%Y}"
    },
    "custom/power": {
        "format": "\uf011",
        "on-click": "hyprlock",
        "tooltip": false
    }
}
EOF

# --- 8. Waybar (style.css) ----------------------------------------------------
cat << 'EOF' > "${SKEL_CONFIG}/waybar/style.css"
* {
    font-family: "JetBrains Mono", "Font Awesome 6 Free", "Font Awesome 5 Free", FontAwesome, sans-serif;
    font-size: 13px;
    font-weight: bold;
}

window#waybar {
    background: rgba(24, 24, 37, 0.85);
    border: 1px solid rgba(203, 166, 247, 0.25);
    border-radius: 12px;
    color: #cdd6f4;
}

#workspaces button {
    padding: 0 8px;
    color: #a6adc8;
    border-radius: 8px;
    background: transparent;
}

#workspaces button.active {
    color: #11111b;
    background: linear-gradient(45deg, #cba6f7, #89b4fa);
    border-radius: 8px;
}

#workspaces button:hover {
    background: rgba(203, 166, 247, 0.2);
    color: #cba6f7;
}

#window, #mpris, #pulseaudio, #network, #battery, #clock, #tray, #custom-power {
    background: rgba(30, 30, 46, 0.6);
    padding: 2px 12px;
    margin: 4px 2px;
    border-radius: 8px;
    border: 1px solid rgba(203, 166, 247, 0.1);
}

#clock { color: #89b4fa; }
#battery { color: #a6e3a1; }
#battery.warning { color: #f9e2af; }
#battery.critical { color: #f38ba8; }
#custom-power { color: #f38ba8; padding: 0 10px; }
EOF

# --- 9. Rofi ------------------------------------------------------------------
cat << 'EOF' > "${SKEL_CONFIG}/rofi/config.rasi"
configuration {
    modes: "drun,run";
    font: "JetBrains Mono 12";
    show-icons: true;
    icon-theme: "Papirus-Dark";
    display-drun: "Aplicaciones";
    drun-display-format: "{icon} {name}";
    hover-select: true;
}

@theme "catppuccin-mocha"
EOF

cat << 'EOF' > "${SKEL_CONFIG}/rofi/catppuccin-mocha.rasi"
* {
    bg: #1e1e2e;
    bg-alt: #313244;
    fg: #cdd6f4;
    accent: #cba6f7;
    urgent: #f38ba8;

    background-color: transparent;
    text-color: @fg;
}

window {
    width: 600px;
    background-color: @bg;
    border: 2px solid;
    border-color: @accent;
    border-radius: 16px;
    padding: 20px;
}

mainbox {
    spacing: 15px;
}

inputbar {
    background-color: @bg-alt;
    border-radius: 10px;
    padding: 12px;
    spacing: 10px;
    children: [prompt, entry];
}

prompt {
    text-color: @accent;
}

entry {
    placeholder: "Buscar aplicaciones...";
    placeholder-color: #6c7086;
}

listview {
    columns: 1;
    lines: 7;
    spacing: 8px;
    background-color: transparent;
}

element {
    padding: 10px;
    border-radius: 8px;
    spacing: 10px;
}

element selected {
    background-color: @accent;
    text-color: #11111b;
}

element-icon {
    size: 24px;
}

element-text {
    vertical-align: 0.5;
}
EOF

# --- 10. SwayNC ---------------------------------------------------------------
cat << 'EOF' > "${SKEL_CONFIG}/swaync/config.json"
{
  "$schema": "/etc/xdg/swaync/configSchema.json",
  "positionX": "right",
  "positionY": "top",
  "control-center-width": 380,
  "control-center-height": 600,
  "notification-window-width": 400,
  "keyboard-shortcuts": true,
  "image-visibility": "when-available",
  "transition-time": 200,
  "hide-on-clear": false,
  "hide-on-action": true,
  "script-fail-notify": true,
  "widgets": [
    "title",
    "dnd",
    "notifications",
    "mpris",
    "volume",
    "backlight",
    "buttons-grid"
  ],
  "widget-config": {
    "title": {
      "text": "Centro de control",
      "clear-all-button": true,
      "button-text": "Limpiar"
    },
    "dnd": {
      "text": "No molestar"
    },
    "mpris": {
      "image-size": 96,
      "image-radius": 12
    },
    "volume": {
      "label": "Vol"
    },
    "backlight": {
      "label": "Brillo"
    },
    "buttons-grid": {
      "actions": [
        { "label": "Red", "command": "nm-connection-editor" },
        { "label": "BT", "command": "blueman-manager" },
        { "label": "Audio", "command": "pavucontrol" },
        { "label": "Tema Qt", "command": "qt6ct" }
      ]
    }
  }
}
EOF

cat << 'EOF' > "${SKEL_CONFIG}/swaync/style.css"
@define-color bg #1e1e2e;
@define-color bg-alt #313244;
@define-color fg #cdd6f4;
@define-color accent #cba6f7;
@define-color urgent #f38ba8;

.control-center {
    background: rgba(30, 30, 46, 0.95);
    border: 2px solid @accent;
    border-radius: 16px;
    color: @fg;
    padding: 16px;
}

.widget-title {
    color: @accent;
    font-size: 16px;
    font-weight: bold;
}

.widget-buttons-grid {
    padding: 8px;
    background: @bg-alt;
    border-radius: 12px;
}

.widget-buttons-grid > flowbox > flowboxchild > button {
    background: @bg;
    color: @fg;
    border-radius: 8px;
    padding: 12px;
}

.notification {
    background: @bg-alt;
    border: 1px solid @accent;
    border-radius: 12px;
    margin: 8px;
    padding: 12px;
    color: @fg;
}
EOF

# --- 11. Kitty ----------------------------------------------------------------
cat << 'EOF' > "${SKEL_CONFIG}/kitty/kitty.conf"
# Kitty - Catppuccin Mocha
font_family      JetBrains Mono
font_size        11.0
bold_font        auto
italic_font      auto
bold_italic_font auto

background_opacity 0.85
window_padding_width 12

foreground           #cdd6f4
background           #1e1e2e
selection_foreground #1e1e2e
selection_background #f5e0dc

cursor               #f5e0dc
cursor_text_color    #1e1e2e
url_color            #f5e0dc

color0               #45475a
color8               #585b70
color1               #f38ba8
color9               #f38ba8
color2               #a6e3a1
color10              #a6e3a1
color3               #f9e2af
color11              #f9e2af
color4               #89b4fa
color12              #89b4fa
color5               #f5c2e7
color13              #f5c2e7
color6               #94e2d5
color14              #94e2d5
color7               #bac2de
color15              #a6adc8
EOF

# --- 12. GTK ------------------------------------------------------------------
cat << 'EOF' > "${SKEL_CONFIG}/gtk-3.0/settings.ini"
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Adwaita
gtk-font-name=JetBrains Mono 11
gtk-application-prefer-dark-theme=1
EOF

cat << 'EOF' > "${SKEL_CONFIG}/gtk-4.0/settings.ini"
[Settings]
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Adwaita
gtk-font-name=JetBrains Mono 11
gtk-application-prefer-dark-theme=1
EOF

# 13. El usuario "larp" ya existe cuando corre %post: /etc/skel no se copia solo
if [ -d /home/larp ]; then
    cp -rT /etc/skel/.config /home/larp/.config
    chown -R larp:larp /home/larp
fi

echo "[+] larp.OS post-install completado."
%end
