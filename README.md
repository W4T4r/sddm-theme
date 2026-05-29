# sddm-theme

SDDM theme based on
[sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme) by
Keyitdev, with wallpaper variants from
[NixOS/nixos-artwork](https://github.com/NixOS/nixos-artwork/tree/master/wallpapers).

Original project:

- Copyright (C) 2022-2025 Keyitdev
- Licensed under GPL-3.0-or-later
- Repository: <https://github.com/Keyitdev/sddm-astronaut-theme>

This repository contains a modified SDDM theme with selectable wallpaper
variants and a Nix flake package.

## Variants

The default variant is `nixos-gear`.

Available variants:

- `nixos-binary-black`
- `nixos-binary-blue`
- `nixos-catppuccin-macchiato`
- `nixos-catppuccin-mocha`
- `nixos-gear`
- `nixos-moonscape`
- `nixos-mosaic-blue`
- `nixos-nineish-dark-gray`
- `nixos-recursive`
- `nixos-simple-dark-gray`
- `nixos-waterfall`
- `nixos-watersplash`

## Previews

| `nixos-binary-black` | `nixos-binary-blue` | `nixos-catppuccin-macchiato` |
| --- | --- | --- |
| ![nixos-binary-black](./Previews/nixos-binary-black.png) | ![nixos-binary-blue](./Previews/nixos-binary-blue.png) | ![nixos-catppuccin-macchiato](./Previews/nixos-catppuccin-macchiato.png) |

| `nixos-catppuccin-mocha` | `nixos-gear` | `nixos-moonscape` |
| --- | --- | --- |
| ![nixos-catppuccin-mocha](./Previews/nixos-catppuccin-mocha.png) | ![nixos-gear](./Previews/nixos-gear.png) | ![nixos-moonscape](./Previews/nixos-moonscape.png) |

| `nixos-mosaic-blue` | `nixos-nineish-dark-gray` | `nixos-recursive` |
| --- | --- | --- |
| ![nixos-mosaic-blue](./Previews/nixos-mosaic-blue.png) | ![nixos-nineish-dark-gray](./Previews/nixos-nineish-dark-gray.png) | ![nixos-recursive](./Previews/nixos-recursive.png) |

| `nixos-simple-dark-gray` | `nixos-waterfall` | `nixos-watersplash` |
| --- | --- | --- |
| ![nixos-simple-dark-gray](./Previews/nixos-simple-dark-gray.png) | ![nixos-waterfall](./Previews/nixos-waterfall.png) | ![nixos-watersplash](./Previews/nixos-watersplash.png) |

Supported background formats follow the upstream theme: `png`, `jpg`, `jpeg`,
`webp`, `gif`, `avi`, `mp4`, `mov`, `mkv`, `m4v`, and `webm`.

Generate static comparison previews:

```sh
tools/preview-variants.sh
```

## Nix Usage

Build the theme package:

```sh
nix build
```

Use it from another flake:

```nix
{
  inputs.sddm-theme.url = "github:W4T4r/sddm-theme";
}
```

Then install and select it in NixOS:

```nix
{ inputs, pkgs, ... }: {
  environment.systemPackages = [
    inputs.sddm-theme.packages.${pkgs.system}.default
  ];

  services.displayManager.sddm.theme = "sddm-theme";
}
```

Or import the included NixOS module and select a variant:

```nix
{ inputs, ... }: {
  imports = [
    inputs.sddm-theme.nixosModules.default
  ];

  services.sddmTheme.enable = true;
  services.sddmTheme.variant = "nixos-catppuccin-mocha";
}
```

The module installs the theme package, sets
`services.displayManager.sddm.theme = "sddm-theme"`, and patches
`metadata.desktop` to point at the selected variant.

## Manual Installation

Install dependencies:

- `sddm >= 0.21.0`
- `qt6 >= 6.8`
- `qt6-svg >= 6.8`
- `qt6-virtualkeyboard >= 6.8`
- `qt6-multimedia >= 6.8`

Clone this repository:

```sh
sudo git clone -b main --depth 1 https://github.com/W4T4r/sddm-theme.git /usr/share/sddm/themes/sddm-theme
```

Copy fonts:

```sh
sudo cp -r /usr/share/sddm/themes/sddm-theme/Fonts/* /usr/share/fonts/
```

Select the theme:

```sh
echo "[Theme]
Current=sddm-theme" | sudo tee /etc/sddm.conf
```

Enable the virtual keyboard:

```sh
sudo mkdir -p /etc/sddm.conf.d
echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf
```

Preview:

```sh
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-theme/
```

## License

Distributed under the GPL-3.0-or-later license.

This project is a modified work based on
[sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme).

Bundled wallpapers retain their original licenses. See
[ATTRIBUTION.md](./ATTRIBUTION.md).
