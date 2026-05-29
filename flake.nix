{
  description = "SDDM theme with combinable backgrounds and layout compositions";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      lib = nixpkgs.lib;
      themeName = "sddm-theme";
      defaultComposition = "center";
      defaultBackground = "nixos-gear";
      defaultFont = "Open Sans";
      fontFamilies = [
        "Open Sans"
        "ArcadeClassic"
        "ESPACION"
        "Electroharmonix"
        "Fragile Bombers"
        "Fragile Bombers Attack"
        "Fragile Bombers Down"
        "KogniGear"
        "Orbitron"
        "Pixelon"
        "Thunderman"
      ];
      supportedBackgroundExtensions = [
        "png"
        "jpg"
        "jpeg"
        "webp"
        "gif"
        "avi"
        "mp4"
        "mov"
        "mkv"
        "m4v"
        "webm"
      ];
      staticScreenshotExtensions = [
        "png"
        "jpg"
        "jpeg"
        "webp"
      ];
      backgroundDir = builtins.readDir ./Backgrounds;
      fileExtension =
        file:
        let
          parts = lib.splitString "." file;
        in
        if builtins.length parts < 2 then null else lib.toLower (lib.last parts);
      fileStem =
        file:
        let
          parts = lib.splitString "." file;
        in
        if builtins.length parts < 2 then file else lib.concatStringsSep "." (lib.init parts);
      isSupportedBackground =
        file:
        backgroundDir.${file} == "regular"
        && builtins.elem (fileExtension file) supportedBackgroundExtensions;
      backgroundFiles = builtins.sort builtins.lessThan (
        builtins.filter isSupportedBackground (builtins.attrNames backgroundDir)
      );
      backgroundFileById = builtins.listToAttrs (
        map (file: {
          name = fileStem file;
          value = file;
        }) backgroundFiles
      );
      compositions = [
        "center"
        "left"
        "right"
      ];
      backgrounds = builtins.attrNames backgroundFileById;
      variants = backgrounds;
      defaultVariant = defaultBackground;
      compositionSettings = {
        center = {
          PartialBlur = "true";
          FullBlur = "";
          HaveFormBackground = "false";
          FormPosition = "center";
          VirtualKeyboardPosition = "center";
        };
        left = {
          PartialBlur = "false";
          FullBlur = "";
          HaveFormBackground = "true";
          FormPosition = "left";
          VirtualKeyboardPosition = "left";
        };
        right = {
          PartialBlur = "false";
          FullBlur = "";
          HaveFormBackground = "true";
          FormPosition = "right";
          VirtualKeyboardPosition = "right";
        };
      };
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
      mkTheme =
        pkgs:
        {
          background ? null,
          composition ? defaultComposition,
          font ? defaultFont,
          variant ? null,
        }:
        let
          selectedBackground =
            if background != null then
              background
            else if variant != null then
              variant
            else
              defaultBackground;
          selectedComposition = composition;
          selectedBackgroundFile = backgroundFileById.${selectedBackground};
          selectedBackgroundPath = "Backgrounds/${selectedBackgroundFile}";
          selectedBackgroundExtension = fileExtension selectedBackgroundFile;
          selectedPreviewPath = ./Previews + "/${selectedBackground}.png";
          selectedScreenshot =
            if builtins.pathExists selectedPreviewPath then
              "Previews/${selectedBackground}.png"
            else if builtins.elem selectedBackgroundExtension staticScreenshotExtensions then
              selectedBackgroundPath
            else
              "Previews/${defaultBackground}.png";
          selectedSettings = compositionSettings.${selectedComposition} // {
            Background = selectedBackgroundPath;
            Font = font;
          };
          setSelectedConfig = pkgs.lib.concatStringsSep "\n" (
            pkgs.lib.mapAttrsToList (key: value: ''
              sed -i 's|^${key}=.*|${key}="${value}"|' "$themeDir/Themes/selected.conf"
            '') selectedSettings
          );
        in
        assert builtins.elem selectedBackground backgrounds;
        assert builtins.elem font fontFamilies;
        assert builtins.hasAttr defaultBackground backgroundFileById;
        assert builtins.hasAttr selectedComposition compositionSettings;
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
            cp "$themeDir/Themes/${defaultBackground}.conf" "$themeDir/Themes/selected.conf"
            ${setSelectedConfig}
            substituteInPlace "$themeDir/metadata.desktop" \
              --replace-fail "ConfigFile=Themes/${defaultBackground}.conf" "ConfigFile=Themes/selected.conf" \
              --replace-fail "Screenshot=Previews/${defaultBackground}.png" "Screenshot=${selectedScreenshot}"

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "SDDM theme based on Keyitdev's sddm-astronaut-theme with combinable backgrounds and layout compositions";
            homepage = "https://github.com/W4T4r/sddm-theme";
            license = licenses.gpl3Plus;
            platforms = platforms.linux;
          };
        };

      nixosModule =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.services.sddmTheme;
          selectedBackground = if cfg.variant != null then cfg.variant else cfg.background;
          package =
            if cfg.package == null then
              self.lib.mkSddmTheme pkgs {
                background = selectedBackground;
                inherit (cfg) composition font;
              }
            else
              cfg.package;
        in
        {
          options.services.sddmTheme = {
            enable = lib.mkEnableOption "the SDDM theme";

            composition = lib.mkOption {
              type = lib.types.enum compositions;
              default = defaultComposition;
              description = "Theme layout composition.";
            };

            background = lib.mkOption {
              type = lib.types.enum backgrounds;
              default = defaultBackground;
              description = "Theme background artwork.";
            };

            font = lib.mkOption {
              type = lib.types.enum fontFamilies;
              default = defaultFont;
              description = "Theme font family.";
            };

            variant = lib.mkOption {
              type = lib.types.nullOr (lib.types.enum backgrounds);
              default = null;
              description = "Deprecated alias for background.";
            };

            package = lib.mkOption {
              type = lib.types.nullOr lib.types.package;
              default = null;
              description = "The SDDM theme package to install. If null, a package is generated from the selected composition, background, and font.";
            };
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ package ];
            fonts.packages = [ package ];

            services.displayManager.sddm.theme = themeName;
          };
        };
    in
    {
      lib = {
        inherit
          backgrounds
          compositions
          defaultBackground
          defaultComposition
          defaultFont
          fontFamilies
          variants
          defaultVariant
          ;
        mkSddmTheme = mkTheme;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          theme = mkTheme pkgs { };
          variantPackages = builtins.listToAttrs (
            map (variant: {
              name = "sddm-theme-${variant}";
              value = mkTheme pkgs { background = variant; };
            }) variants
          );
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
