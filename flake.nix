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
      defaultBackgroundDim = 0.0;
      defaultBackgroundColor = "#21222C";
      defaultFormBackgroundColor = "#21222C";
      defaultBlurAmount = 2.0;
      defaultBlurMax = 48;
      defaultFontSize = 13;
      defaultRoundCorners = 20;
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
      clockFormats = [
        "24h"
        "12h"
        "iso"
        "locale"
      ];
      backgrounds = builtins.attrNames backgroundFileById;
      backgroundIds = backgrounds;
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
          background ? { },
          composition ? defaultComposition,
          form ? { },
          font ? { },
          roundCorners ? defaultRoundCorners,
          clockFormat ? defaultClockFormat,
        }:
        let
          formBackground = form.background or { };
          formBlur = form.blur or { };
          selectedBackground = background.name or defaultBackground;
          selectedComposition = composition;
          selectedFormStyle = form.style or defaultFormStyle;
          selectedBackgroundPlacement = background.placement or defaultBackgroundPlacement;
          selectedBackgroundDim = background.dim or defaultBackgroundDim;
          selectedBackgroundColor = background.color or defaultBackgroundColor;
          selectedFormBackgroundColor = formBackground.color or defaultFormBackgroundColor;
          selectedBlurAmount = formBlur.amount or defaultBlurAmount;
          selectedBlurMax = formBlur.max or defaultBlurMax;
          selectedFontFamily = font.family or defaultFont;
          selectedFontSize = font.size or defaultFontSize;
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
              BackgroundColor = selectedBackgroundColor;
              Blur = selectedBlurAmount;
              BlurMax = selectedBlurMax;
              DimBackgroundColor = selectedBackgroundColor;
              DimBackground = selectedBackgroundDim;
              Font = selectedFontFamily;
              FontSize = selectedFontSize;
              FormBackgroundColor = selectedFormBackgroundColor;
              RoundCorners = roundCorners;
            }
            // formStyleSettings.${selectedFormStyle}
            // backgroundPlacementSettings.${selectedBackgroundPlacement}
            // clockFormatSettings.${clockFormat};
          setSelectedConfig = pkgs.lib.concatStringsSep "\n" (
            pkgs.lib.mapAttrsToList (key: value: ''
              sed -i 's|^${key}=.*|${key}="${toString value}"|' "$themeDir/Themes/selected.conf"
            '') selectedSettings
          );
        in
        assert builtins.elem selectedBackground backgrounds;
        assert builtins.elem selectedFormStyle formStyles;
        assert builtins.elem selectedBackgroundPlacement backgroundPlacements;
        assert builtins.elem selectedFontFamily fontFamilies;
        assert selectedBackgroundDim >= 0.0 && selectedBackgroundDim <= 1.0;
        assert selectedBlurAmount >= 0.0 && selectedBlurAmount < 3.0;
        assert selectedBlurMax >= 2;
        assert selectedFontSize > 0;
        assert roundCorners >= 0;
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
          package =
            if cfg.package == null then
              self.lib.mkSddmTheme pkgs {
                inherit (cfg)
                  background
                  composition
                  form
                  font
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

            background = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  name = lib.mkOption {
                    type = lib.types.enum backgrounds;
                    default = defaultBackground;
                    description = "Theme background artwork.";
                  };

                  placement = lib.mkOption {
                    type = lib.types.enum backgroundPlacements;
                    default = defaultBackgroundPlacement;
                    description = "Background scaling and alignment.";
                  };

                  dim = lib.mkOption {
                    type = lib.types.number;
                    default = defaultBackgroundDim;
                    description = "Background dim opacity from 0.0 to 1.0.";
                  };

                  color = lib.mkOption {
                    type = lib.types.str;
                    default = defaultBackgroundColor;
                    description = "Fallback window background color.";
                  };
                };
              };
              default = { };
              description = "Background settings.";
            };

            form = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  style = lib.mkOption {
                    type = lib.types.enum formStyles;
                    default = defaultFormStyle;
                    description = "Form background style.";
                  };

                  background = lib.mkOption {
                    type = lib.types.submodule {
                      options = {
                        color = lib.mkOption {
                          type = lib.types.str;
                          default = defaultFormBackgroundColor;
                          description = "Solid form background color.";
                        };
                      };
                    };
                    default = { };
                    description = "Form background settings.";
                  };

                  blur = lib.mkOption {
                    type = lib.types.submodule {
                      options = {
                        amount = lib.mkOption {
                          type = lib.types.number;
                          default = defaultBlurAmount;
                          description = "Blur amount from 0.0 up to, but not including, 3.0.";
                        };

                        max = lib.mkOption {
                          type = lib.types.number;
                          default = defaultBlurMax;
                          description = "Maximum blur radius.";
                        };
                      };
                    };
                    default = { };
                    description = "Form blur settings.";
                  };
                };
              };
              default = { };
              description = "Form settings.";
            };

            font = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  family = lib.mkOption {
                    type = lib.types.enum fontFamilies;
                    default = defaultFont;
                    description = "Theme font family.";
                  };

                  size = lib.mkOption {
                    type = lib.types.number;
                    default = defaultFontSize;
                    description = "Theme font point size.";
                  };
                };
              };
              default = { };
              description = "Theme font settings.";
            };

            roundCorners = lib.mkOption {
              type = lib.types.number;
              default = defaultRoundCorners;
              description = "Rounded corner radius.";
            };

            clockFormat = lib.mkOption {
              type = lib.types.enum clockFormats;
              default = defaultClockFormat;
              description = "Clock and date format preset.";
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
          backgroundPlacements
          clockFormats
          compositions
          defaultBackground
          defaultBackgroundColor
          defaultBackgroundDim
          defaultBackgroundPlacement
          defaultFormBackgroundColor
          defaultBlurAmount
          defaultBlurMax
          defaultClockFormat
          defaultComposition
          defaultFormStyle
          defaultFont
          defaultFontSize
          defaultRoundCorners
          fontFamilies
          formStyles
          sddmRuntimeDependencies
          backgroundIds
          ;
        mkSddmTheme = mkTheme;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          theme = mkTheme pkgs { };
          backgroundPackages = builtins.listToAttrs (
            map (backgroundId: {
              name = "sddm-theme-${backgroundId}";
              value = mkTheme pkgs { background.name = backgroundId; };
            }) backgroundIds
          );
        in
        {
          sddm-theme = theme;
          default = theme;
        }
        // backgroundPackages
      );

      nixosModules = {
        default = nixosModule;
        sddm-theme = nixosModule;
      };

      formatter = forAllSystems (system: nixpkgsFor.${system}.nixfmt-rfc-style);
    };
}
