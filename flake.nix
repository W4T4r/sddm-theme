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
      defaultFormStyle = "solid";
      defaultBackground = "nixos-gear";
      defaultBackgroundPlacement = "fill";
      defaultFont = "Open Sans";
      defaultBackgroundDim = "none";
      defaultFormBackgroundColor = "#21222C";
      defaultBlurStrength = "normal";
      defaultFontSize = "normal";
      defaultRoundCorners = "normal";
      defaultClockFormat = "24h";
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
      formStyles = [
        "solid"
        "blur"
      ];
      backgroundPlacements = [
        "fill"
        "fit"
        "top"
        "bottom"
        "left"
        "right"
        "top-left"
        "top-right"
        "bottom-left"
        "bottom-right"
      ];
      backgroundDims = [
        "none"
        "light"
        "medium"
        "dark"
      ];
      blurStrengths = [
        "soft"
        "normal"
        "strong"
      ];
      fontSizes = [
        "small"
        "normal"
        "large"
      ];
      roundCornerSizes = [
        "none"
        "small"
        "normal"
        "large"
      ];
      clockFormats = [
        "24h"
        "12h"
        "iso"
        "locale"
      ];
      backgrounds = builtins.attrNames backgroundFileById;
      variants = backgrounds;
      defaultVariant = defaultBackground;
      compositionSettings = {
        center = {
          FormPosition = "center";
          VirtualKeyboardPosition = "center";
        };
        left = {
          FormPosition = "left";
          VirtualKeyboardPosition = "left";
        };
        right = {
          FormPosition = "right";
          VirtualKeyboardPosition = "right";
        };
      };
      formStyleSettings = {
        solid = {
          PartialBlur = "false";
          FullBlur = "";
          HaveFormBackground = "true";
        };
        blur = {
          PartialBlur = "true";
          FullBlur = "";
          HaveFormBackground = "true";
        };
      };
      backgroundPlacementSettings = {
        fill = {
          CropBackground = "true";
          BackgroundHorizontalAlignment = "center";
          BackgroundVerticalAlignment = "center";
        };
        fit = {
          CropBackground = "false";
          BackgroundHorizontalAlignment = "center";
          BackgroundVerticalAlignment = "center";
        };
        top = {
          CropBackground = "false";
          BackgroundHorizontalAlignment = "center";
          BackgroundVerticalAlignment = "top";
        };
        bottom = {
          CropBackground = "false";
          BackgroundHorizontalAlignment = "center";
          BackgroundVerticalAlignment = "bottom";
        };
        left = {
          CropBackground = "false";
          BackgroundHorizontalAlignment = "left";
          BackgroundVerticalAlignment = "center";
        };
        right = {
          CropBackground = "false";
          BackgroundHorizontalAlignment = "right";
          BackgroundVerticalAlignment = "center";
        };
        top-left = {
          CropBackground = "false";
          BackgroundHorizontalAlignment = "left";
          BackgroundVerticalAlignment = "top";
        };
        top-right = {
          CropBackground = "false";
          BackgroundHorizontalAlignment = "right";
          BackgroundVerticalAlignment = "top";
        };
        bottom-left = {
          CropBackground = "false";
          BackgroundHorizontalAlignment = "left";
          BackgroundVerticalAlignment = "bottom";
        };
        bottom-right = {
          CropBackground = "false";
          BackgroundHorizontalAlignment = "right";
          BackgroundVerticalAlignment = "bottom";
        };
      };
      backgroundDimSettings = {
        none = {
          DimBackground = "0.0";
        };
        light = {
          DimBackground = "0.2";
        };
        medium = {
          DimBackground = "0.4";
        };
        dark = {
          DimBackground = "0.6";
        };
      };
      blurStrengthSettings = {
        soft = {
          Blur = "1.0";
          BlurMax = "32";
        };
        normal = {
          Blur = "2.0";
          BlurMax = "48";
        };
        strong = {
          Blur = "2.8";
          BlurMax = "64";
        };
      };
      fontSizeSettings = {
        small = {
          FontSize = "11";
        };
        normal = {
          FontSize = "13";
        };
        large = {
          FontSize = "16";
        };
      };
      roundCornerSettings = {
        none = {
          RoundCorners = "0";
        };
        small = {
          RoundCorners = "12";
        };
        normal = {
          RoundCorners = "20";
        };
        large = {
          RoundCorners = "28";
        };
      };
      clockFormatSettings = {
        "24h" = {
          HourFormat = "HH:mm";
          DateFormat = "dddd d MMMM";
        };
        "12h" = {
          HourFormat = "h:mm AP";
          DateFormat = "dddd d MMMM";
        };
        iso = {
          HourFormat = "HH:mm";
          DateFormat = "yyyy-MM-dd";
        };
        locale = {
          HourFormat = "";
          DateFormat = "";
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
      sddmRuntimeDependencies =
        pkgs: with pkgs.kdePackages; [
          qtsvg
          qtmultimedia
          qtvirtualkeyboard
        ];
      mkTheme =
        pkgs:
        {
          background ? null,
          composition ? defaultComposition,
          formStyle ? defaultFormStyle,
          backgroundPlacement ? defaultBackgroundPlacement,
          font ? defaultFont,
          backgroundDim ? defaultBackgroundDim,
          formBackgroundColor ? defaultFormBackgroundColor,
          blurStrength ? defaultBlurStrength,
          fontSize ? defaultFontSize,
          roundCorners ? defaultRoundCorners,
          clockFormat ? defaultClockFormat,
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
          selectedSettings =
            compositionSettings.${selectedComposition}
            // {
              Background = selectedBackgroundPath;
              Font = font;
              FormBackgroundColor = formBackgroundColor;
            }
            // formStyleSettings.${formStyle}
            // backgroundPlacementSettings.${backgroundPlacement}
            // backgroundDimSettings.${backgroundDim}
            // blurStrengthSettings.${blurStrength}
            // fontSizeSettings.${fontSize}
            // roundCornerSettings.${roundCorners}
            // clockFormatSettings.${clockFormat};
          setSelectedConfig = pkgs.lib.concatStringsSep "\n" (
            pkgs.lib.mapAttrsToList (key: value: ''
              sed -i 's|^${key}=.*|${key}="${value}"|' "$themeDir/Themes/selected.conf"
            '') selectedSettings
          );
        in
        assert builtins.elem selectedBackground backgrounds;
        assert builtins.elem formStyle formStyles;
        assert builtins.elem backgroundPlacement backgroundPlacements;
        assert builtins.elem font fontFamilies;
        assert builtins.elem backgroundDim backgroundDims;
        assert builtins.elem blurStrength blurStrengths;
        assert builtins.elem fontSize fontSizes;
        assert builtins.elem roundCorners roundCornerSizes;
        assert builtins.elem clockFormat clockFormats;
        assert builtins.hasAttr defaultBackground backgroundFileById;
        assert builtins.hasAttr selectedComposition compositionSettings;
        pkgs.stdenvNoCC.mkDerivation {
          pname = themeName;
          version = "0.1.0";

          src = pkgs.lib.cleanSource ./.;

          dontConfigure = true;
          dontBuild = true;

          propagatedUserEnvPkgs = sddmRuntimeDependencies pkgs;
          passthru.runtimeDependencies = sddmRuntimeDependencies pkgs;

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
                inherit (cfg)
                  composition
                  formStyle
                  backgroundPlacement
                  font
                  backgroundDim
                  formBackgroundColor
                  blurStrength
                  fontSize
                  roundCorners
                  clockFormat
                  ;
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

            formStyle = lib.mkOption {
              type = lib.types.enum formStyles;
              default = defaultFormStyle;
              description = "Form background style.";
            };

            background = lib.mkOption {
              type = lib.types.enum backgrounds;
              default = defaultBackground;
              description = "Theme background artwork.";
            };

            backgroundPlacement = lib.mkOption {
              type = lib.types.enum backgroundPlacements;
              default = defaultBackgroundPlacement;
              description = "Background scaling and alignment.";
            };

            font = lib.mkOption {
              type = lib.types.enum fontFamilies;
              default = defaultFont;
              description = "Theme font family.";
            };

            backgroundDim = lib.mkOption {
              type = lib.types.enum backgroundDims;
              default = defaultBackgroundDim;
              description = "Background dim preset.";
            };

            formBackgroundColor = lib.mkOption {
              type = lib.types.str;
              default = defaultFormBackgroundColor;
              description = "Solid form background color.";
            };

            blurStrength = lib.mkOption {
              type = lib.types.enum blurStrengths;
              default = defaultBlurStrength;
              description = "Blur strength preset for blur form style.";
            };

            fontSize = lib.mkOption {
              type = lib.types.enum fontSizes;
              default = defaultFontSize;
              description = "Theme font size preset.";
            };

            roundCorners = lib.mkOption {
              type = lib.types.enum roundCornerSizes;
              default = defaultRoundCorners;
              description = "Rounded corner size preset.";
            };

            clockFormat = lib.mkOption {
              type = lib.types.enum clockFormats;
              default = defaultClockFormat;
              description = "Clock and date format preset.";
            };

            variant = lib.mkOption {
              type = lib.types.nullOr (lib.types.enum backgrounds);
              default = null;
              description = "Deprecated alias for background.";
            };

            package = lib.mkOption {
              type = lib.types.nullOr lib.types.package;
              default = null;
              description = "The SDDM theme package to install. If null, a package is generated from the selected theme options.";
            };
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ package ];
            fonts.packages = [ package ];

            services.displayManager.sddm = {
              theme = themeName;
              extraPackages = lib.mkAfter (sddmRuntimeDependencies pkgs);
            };
          };
        };
    in
    {
      lib = {
        inherit
          backgrounds
          backgroundDims
          backgroundPlacements
          blurStrengths
          clockFormats
          compositions
          defaultBackground
          defaultBackgroundDim
          defaultBackgroundPlacement
          defaultFormBackgroundColor
          defaultBlurStrength
          defaultClockFormat
          defaultComposition
          defaultFormStyle
          defaultFont
          defaultFontSize
          defaultRoundCorners
          fontFamilies
          fontSizes
          formStyles
          roundCornerSizes
          sddmRuntimeDependencies
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
