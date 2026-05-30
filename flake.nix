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
      defaultFormStyle = "blur";
      defaultBackground = "nixos-nineish-dark-gray";
      defaultBackgroundPlacement = "fill";
      defaultFont = "Orbitron";
      defaultBackgroundDim = 0.2;
      defaultBackgroundColor = "#101820";
      defaultFormBackgroundColor = "#80262626";
      defaultTextColor = "#eeeeee";
      defaultMutedTextColor = "#999999";
      defaultAccentColor = "#66ccff";
      defaultInputBackgroundColor = "#20242c";
      defaultButtonBackgroundColor = "#303846";
      defaultBlurAmount = 2.4;
      defaultBlurMax = 60;
      defaultFormWidthRatio = 0.45;
      defaultFontSize = 13;
      defaultRoundCorners = 18;
      defaultClockFormat = "24h";
      defaultClockLocale = "en_US";
      defaultSystemButtonsVisible = false;
      defaultVirtualKeyboardVisible = false;
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
          clock ? { },
          colors ? { },
          composition ? defaultComposition,
          form ? { },
          font ? { },
          roundCorners ? defaultRoundCorners,
          systemButtons ? { },
          virtualKeyboard ? { },
        }:
        let
          formBackground = form.background or { };
          formBlur = form.blur or { };
          colorInput = colors.input or { };
          colorButton = colors.button or { };
          selectedBackground = background.name or defaultBackground;
          selectedComposition = composition;
          selectedFormStyle = form.style or defaultFormStyle;
          selectedFormWidthRatio = form.widthRatio or defaultFormWidthRatio;
          selectedBackgroundPlacement = background.placement or defaultBackgroundPlacement;
          selectedBackgroundDim = background.dim or defaultBackgroundDim;
          selectedBackgroundColor = background.color or defaultBackgroundColor;
          selectedFormBackgroundColor = formBackground.color or defaultFormBackgroundColor;
          selectedTextColor = colors.text or defaultTextColor;
          selectedMutedTextColor = colors.mutedText or defaultMutedTextColor;
          selectedAccentColor = colors.accent or defaultAccentColor;
          selectedInputBackgroundColor = colorInput.background or defaultInputBackgroundColor;
          selectedButtonBackgroundColor = colorButton.background or defaultButtonBackgroundColor;
          selectedBlurAmount = formBlur.amount or defaultBlurAmount;
          selectedBlurMax = formBlur.max or defaultBlurMax;
          selectedFontFamily = font.family or defaultFont;
          selectedFontSize = font.size or defaultFontSize;
          selectedClockFormat = clock.format or defaultClockFormat;
          selectedClockLocale = clock.locale or defaultClockLocale;
          selectedSystemButtonsVisible = systemButtons.visible or defaultSystemButtonsVisible;
          selectedVirtualKeyboardVisible = virtualKeyboard.visible or defaultVirtualKeyboardVisible;
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
              DateTextColor = selectedTextColor;
              DimBackgroundColor = selectedBackgroundColor;
              DimBackground = selectedBackgroundDim;
              DropdownBackgroundColor = selectedInputBackgroundColor;
              DropdownSelectedBackgroundColor = selectedButtonBackgroundColor;
              DropdownTextColor = selectedTextColor;
              Font = selectedFontFamily;
              FontSize = selectedFontSize;
              FormWidthRatio = selectedFormWidthRatio;
              FormBackgroundColor = selectedFormBackgroundColor;
              HeaderTextColor = selectedTextColor;
              HideSystemButtons = !selectedSystemButtonsVisible;
              HideVirtualKeyboard = !selectedVirtualKeyboardVisible;
              HighlightBackgroundColor = selectedButtonBackgroundColor;
              HighlightBorderColor = selectedButtonBackgroundColor;
              HighlightTextColor = selectedMutedTextColor;
              HoverPasswordIconColor = selectedAccentColor;
              HoverSessionButtonTextColor = selectedAccentColor;
              HoverSystemButtonsIconsColor = selectedAccentColor;
              HoverUserIconColor = selectedAccentColor;
              HoverVirtualKeyboardButtonTextColor = selectedAccentColor;
              Locale = selectedClockLocale;
              LoginButtonBackgroundColor = selectedButtonBackgroundColor;
              LoginButtonTextColor = selectedTextColor;
              LoginFieldBackgroundColor = selectedInputBackgroundColor;
              LoginFieldTextColor = selectedTextColor;
              PasswordFieldBackgroundColor = selectedInputBackgroundColor;
              PasswordFieldTextColor = selectedTextColor;
              PasswordIconColor = selectedTextColor;
              PlaceholderTextColor = selectedMutedTextColor;
              RoundCorners = roundCorners;
              SessionButtonTextColor = selectedTextColor;
              SystemButtonsIconsColor = selectedTextColor;
              TimeTextColor = selectedTextColor;
              UserIconColor = selectedTextColor;
              VirtualKeyboardButtonTextColor = selectedTextColor;
              WarningColor = selectedButtonBackgroundColor;
            }
            // formStyleSettings.${selectedFormStyle}
            // backgroundPlacementSettings.${selectedBackgroundPlacement}
            // clockFormatSettings.${selectedClockFormat};
          configValueToString =
            value: if builtins.isBool value then lib.boolToString value else toString value;
          setSelectedConfig = pkgs.lib.concatStringsSep "\n" (
            pkgs.lib.mapAttrsToList (key: value: ''
              if grep -q '^${key}=' "$themeDir/Themes/selected.conf"; then
                sed -i 's|^${key}=.*|${key}="${configValueToString value}"|' "$themeDir/Themes/selected.conf"
              else
                printf '%s="%s"\n' '${key}' '${configValueToString value}' >> "$themeDir/Themes/selected.conf"
              fi
            '') selectedSettings
          );
        in
        assert builtins.elem selectedBackground backgrounds;
        assert builtins.elem selectedFormStyle formStyles;
        assert builtins.elem selectedBackgroundPlacement backgroundPlacements;
        assert builtins.elem selectedFontFamily fontFamilies;
        assert selectedBackgroundDim >= 0.0 && selectedBackgroundDim <= 1.0;
        assert selectedFormWidthRatio > 0.0 && selectedFormWidthRatio <= 1.0;
        assert selectedBlurAmount >= 0.0 && selectedBlurAmount < 3.0;
        assert selectedBlurMax >= 2;
        assert selectedFontSize > 0;
        assert roundCorners >= 0;
        assert builtins.elem selectedClockFormat clockFormats;
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
                  clock
                  colors
                  composition
                  form
                  font
                  roundCorners
                  systemButtons
                  virtualKeyboard
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

            colors = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  text = lib.mkOption {
                    type = lib.types.str;
                    default = defaultTextColor;
                    description = "Primary text and icon color.";
                  };

                  mutedText = lib.mkOption {
                    type = lib.types.str;
                    default = defaultMutedTextColor;
                    description = "Muted text and placeholder color.";
                  };

                  accent = lib.mkOption {
                    type = lib.types.str;
                    default = defaultAccentColor;
                    description = "Hover and focus accent color.";
                  };

                  input = lib.mkOption {
                    type = lib.types.submodule {
                      options.background = lib.mkOption {
                        type = lib.types.str;
                        default = defaultInputBackgroundColor;
                        description = "Input and dropdown background color.";
                      };
                    };
                    default = { };
                    description = "Input color settings.";
                  };

                  button = lib.mkOption {
                    type = lib.types.submodule {
                      options.background = lib.mkOption {
                        type = lib.types.str;
                        default = defaultButtonBackgroundColor;
                        description = "Button, highlight, and warning background color.";
                      };
                    };
                    default = { };
                    description = "Button color settings.";
                  };
                };
              };
              default = { };
              description = "Shared theme color settings.";
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

                  widthRatio = lib.mkOption {
                    type = lib.types.number;
                    default = defaultFormWidthRatio;
                    description = "Form width as a fraction of the screen width.";
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

            clock = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  format = lib.mkOption {
                    type = lib.types.enum clockFormats;
                    default = defaultClockFormat;
                    description = "Clock and date format preset.";
                  };

                  locale = lib.mkOption {
                    type = lib.types.str;
                    default = defaultClockLocale;
                    description = "Locale for clock and date formatting.";
                  };
                };
              };
              default = { };
              description = "Clock settings.";
            };

            systemButtons = lib.mkOption {
              type = lib.types.submodule {
                options.visible = lib.mkOption {
                  type = lib.types.bool;
                  default = defaultSystemButtonsVisible;
                  description = "Whether shutdown, reboot, suspend, and hibernate buttons are visible.";
                };
              };
              default = { };
              description = "System button settings.";
            };

            virtualKeyboard = lib.mkOption {
              type = lib.types.submodule {
                options.visible = lib.mkOption {
                  type = lib.types.bool;
                  default = defaultVirtualKeyboardVisible;
                  description = "Whether the virtual keyboard toggle is visible.";
                };
              };
              default = { };
              description = "Virtual keyboard settings.";
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
          defaultAccentColor
          defaultBlurAmount
          defaultBlurMax
          defaultClockFormat
          defaultClockLocale
          defaultComposition
          defaultButtonBackgroundColor
          defaultFormBackgroundColor
          defaultFormWidthRatio
          defaultFormStyle
          defaultFont
          defaultFontSize
          defaultInputBackgroundColor
          defaultMutedTextColor
          defaultRoundCorners
          defaultSystemButtonsVisible
          defaultTextColor
          defaultVirtualKeyboardVisible
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
