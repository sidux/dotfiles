{
  description = "Example Darwin system flake with home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, darwin, nixpkgs, home-manager }:
  let
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
    user = "<user>";
    host = "<host>";
  in
  {
    darwinConfigurations."${host}" = darwin.lib.darwinSystem {
      inherit system;
      modules = [
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${user} = { pkgs, ... }: {
            home.stateVersion = "24.05";

            programs.git = {
              enable = true;
              userName = "sidux";
              userEmail = "ahmed.lebbada@gmail.com";
              ignores = [ ".DS_Store" "*.swp" ];
              extraConfig = {
                core = {
                  editor = "code";
                };
                color = {
                  ui = true;
                };
              };
            };

            programs.vscode = {
              enable = true;
              package = pkgs.vscode;
            };

            fonts.fontconfig.enable = true;

            # Copy a custom file
            # home.file.".custom_file".source = ./path/to/your/custom_file;

            # You can add more home-manager configurations here
          };
        }
        ({ pkgs, ... }: {
          nixpkgs.hostPlatform = "aarch64-darwin";
          nixpkgs.config.allowUnfree = true;

          # Your system configuration
          environment.systemPackages = with pkgs; [
            htop
            devenv
            jq
            yq-go
            nodejs_20
            nixpkgs-fmt
            vscode
            iterm2
            jetbrains-mono
          ];
          services.nix-daemon.enable = true;
          nix.settings.experimental-features = [ "nix-command" "flakes" ];


          programs.direnv.enable = true;

          programs.zsh.enable = true;

          programs.fish = {
            enable = true;
            useBabelfish = true;
          };


          users.users.${user} = {
            name = user;
            home = "/Users/${user}";
            shell = pkgs.fish;
          };

          environment.shells = with pkgs; [ zsh fish ];

          system.stateVersion = 4;

          security.pam.enableSudoTouchIdAuth = true;

          system.defaults = {
            ".GlobalPreferences"."com.apple.mouse.scaling" = 4.0;
            spaces.spans-displays = true;

            dock = {
              autohide = true;
              autohide-delay = 0.0;
              autohide-time-modifier = 0.0;
              orientation = "bottom";
              dashboard-in-overlay = true;
              largesize = 85;
              tilesize = 50;
              magnification = true;
              launchanim = false;
              mru-spaces = false;
              show-recents = false;
              show-process-indicators = false;
              static-only = true;
              mouse-over-hilite-stack = true;
              wvous-tl-corner = 2;
              wvous-bl-corner = 4;
              # wvous-tl-modifier = 0;
              # wvous-bl-modifier = 0;
            };

            finder = {
              AppleShowAllExtensions = true;
              AppleShowAllFiles = true;
              CreateDesktop = false;
              FXDefaultSearchScope = "SCcf"; # current folder
              QuitMenuItem = true;
              ShowPathbar = true;
              _FXShowPosixPathInTitle = true;
              # NewWindowTarget = "PfHm";
              # NewWindowTargetPath = "file:///Users/${user}/";
              # _FXSortFoldersFirst = true;
            };

            NSGlobalDomain = {
              _HIHideMenuBar = false;
              AppleFontSmoothing = 0;
              AppleInterfaceStyle = "Dark";
              AppleKeyboardUIMode = 3;
              AppleScrollerPagingBehavior = true;
              AppleShowAllExtensions = true;
              AppleShowAllFiles = true;
              InitialKeyRepeat = 10;
              KeyRepeat = 2;
              NSAutomaticSpellingCorrectionEnabled = false;
              NSAutomaticWindowAnimationsEnabled = false;
              # Expand save panel by default
              NSNavPanelExpandedStateForSaveMode = true;
              NSNavPanelExpandedStateForSaveMode2 = true;
              NSWindowResizeTime = 0.0;
              # Disable “natural” scrolling
              "com.apple.swipescrolldirection" = false;
              "com.apple.sound.beep.feedback" = 0;
              "com.apple.trackpad.scaling" = 2.0;
              # Increase sound quality for Bluetooth headphones/headsets
              # "com.apple.BluetoothAudioAgent" = {
              #   "Apple Bitpool Min (editable)" = 40;
              # };
            };
          };
        })
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."${host}".pkgs;
  };
}