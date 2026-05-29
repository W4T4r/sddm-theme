{
  description = "SDDM theme with NixOS artwork variants";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    themeName = "sddm-theme";
    defaultVariant = "nixos-gear";
    variants = [
      "nixos-binary-black"
      "nixos-binary-blue"
      "nixos-catppuccin-macchiato"
      "nixos-catppuccin-mocha"
      "nixos-gear"
      "nixos-moonscape"
      "nixos-mosaic-blue"
      "nixos-nineish-dark-gray"
      "nixos-recursive"
      "nixos-simple-dark-gray"
      "nixos-waterfall"
      "nixos-watersplash"
    ];
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (
      system:
        import nixpkgs {
          inherit system;
        }
    );
    mkTheme = pkgs: {variant ? defaultVariant}:
      assert builtins.elem variant variants;
        pkgs.stdenvNoCC.mkDerivation {
          pname = themeName;
          version = "0.1.0";

          src = pkgs.lib.cleanSource ./.;

          dontConfigure = true;
          dontBuild = true;

          installPhase = ''
              runHook preInstall

              themeDir="$out/share/sddm/themes/${themeName}"
              mkdir -p "$themeDir" "$out/share/fonts/truetype/${themeName}"

            cp -r Assets Backgrounds Components Fonts Previews Themes Main.qml metadata.desktop LICENSE ATTRIBUTION.md "$themeDir"/
              cp -r Fonts/* "$out/share/fonts/truetype/${themeName}"/
              substituteInPlace "$themeDir/metadata.desktop" \
                --replace-fail "ConfigFile=Themes/${defaultVariant}.conf" "ConfigFile=Themes/${variant}.conf" \
                --replace-fail "Screenshot=Previews/${defaultVariant}.png" "Screenshot=Previews/${variant}.png"

              runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "SDDM theme based on Keyitdev's sddm-astronaut-theme with NixOS artwork variants";
            homepage = "https://github.com/W4T4r/sddm-theme";
            license = licenses.gpl3Plus;
            platforms = platforms.linux;
          };
        };

    nixosModule = {
      config,
      lib,
      pkgs,
      ...
    }: let
      cfg = config.services.sddmTheme;
      package =
        if cfg.package == null
        then self.lib.mkSddmTheme pkgs {inherit (cfg) variant;}
        else cfg.package;
    in {
      options.services.sddmTheme = {
        enable = lib.mkEnableOption "the SDDM theme";

        variant = lib.mkOption {
          type = lib.types.enum variants;
          default = defaultVariant;
          description = "Theme variant to select in metadata.desktop.";
        };

        package = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = null;
          description = "The SDDM theme package to install. If null, a package is generated from the selected variant.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [package];
        fonts.packages = [package];

        services.displayManager.sddm.theme = themeName;
      };
    };
  in {
    lib = {
      inherit variants defaultVariant;
      mkSddmTheme = mkTheme;
    };

    packages = forAllSystems (
      system: let
        pkgs = nixpkgsFor.${system};
        theme = mkTheme pkgs {};
        variantPackages =
          builtins.listToAttrs
          (map (variant: {
              name = "sddm-theme-${variant}";
              value = mkTheme pkgs {inherit variant;};
            })
            variants);
      in
        {
          sddm-theme = theme;
          default = theme;
        }
        // variantPackages
    );

    nixosModules = {
      default = nixosModule;
      sddm-theme = nixosModule;
    };

    formatter = forAllSystems (system: nixpkgsFor.${system}.nixfmt-rfc-style);
  };
}
