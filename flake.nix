{
  description = "Simplified Darwin system flake with home-manager";

  # Input sources for this flake
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

  # Output configurations
  outputs = inputs@{ self, darwin, nixpkgs, home-manager }:
  let
    # System configuration
    system = "aarch64-darwin";  # Specifies the system architecture (ARM-based macOS)
    pkgs = nixpkgs.legacyPackages.${system};
    user = "<user>";  # Placeholder for the username
    host = "<host>";  # Placeholder for the hostname
  in
  {
    # Darwin configuration
    darwinConfigurations."${host}" = darwin.lib.darwinSystem {
      inherit system;
      modules = [
        # Home Manager configuration
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;  # Use global packages in home-manager
          home-manager.useUserPackages = true;  # Install user packages to /etc/profiles
          home-manager.users.${user} = { pkgs, ... }: {
            home.stateVersion = "24.05";  # Specify the state version for home-manager

            # Git configuration
            programs.git = {
              enable = true;
              userName = "sidux";
              userEmail = "ahmed.lebbada@gmail.com";
              ignores = [ ".DS_Store" "*.swp" ];  # Files to ignore in Git
              extraConfig = {
                core.editor = "vim";  # Set VS Code as the default Git editor
                color.ui = true;  # Enable colorized output in Git
              };
            };

            # Enable font configuration
            fonts.fontconfig.enable = true;  # Enable fontconfig for managing fonts
          };
        }

        # System-wide configuration
        ({ pkgs, ... }: {

          # Basic system settings
          nixpkgs.hostPlatform = "aarch64-darwin";  # Specify the host platform
          nixpkgs.config.allowUnfree = true;  # Allow installation of proprietary software
          services.nix-daemon.enable = true;  # Enable the Nix daemon
          nix.settings.experimental-features = [ "nix-command" "flakes" ];  # Enable experimental Nix features
          system.stateVersion = 4;  # Specify the system state version

          # System packages
          environment.systemPackages = with pkgs; [
            htop
            gh
            devenv
            jq
            yq-go
            nodejs_20
            nixpkgs-fmt
            vscode
            iterm2
            jetbrains-mono
            stats
            raycast
            hidden-bar
            monitorcontrol
            jankyborders
          ];

          # Shell configurations
          programs.direnv.enable = true;  # Enable direnv for directory-specific environments
          programs.zsh.enable = true;  # Enable Zsh shell

          programs.fish = {
            enable = true;
            useBabelfish = true;  # Enable Babelfish for improved shell compatibility
          };

          # User configuration
          users.users.${user} = {
            name = user;
            home = "/Users/${user}";
            shell = pkgs.fish;  # Set Fish as the default shell for the user
          };

          environment.shells = with pkgs; [ zsh fish ];  # Specify available shells

          # Enable Touch ID for sudo
          security.pam.enableSudoTouchIdAuth = true;  # Allow using Touch ID for sudo authentication

          # macOS system preferences
          system.defaults = {
            # Mouse settings
            ".GlobalPreferences"."com.apple.mouse.scaling" = 4.0;  # Set mouse scaling (speed)
            
            # Spaces settings
            spaces.spans-displays = true;  # Allow spaces to span multiple displays

            # Dock settings
            dock = {
              autohide = true;  # Automatically hide the Dock
              autohide-delay = 0.0;  # No delay when showing the Dock
              autohide-time-modifier = 0.0;  # Instant Dock hiding/showing
              orientation = "bottom";  # Place the Dock at the bottom of the screen
              tilesize = 50;  # Set the size of Dock icons
              magnification = true;  # Enable Dock icon magnification
              static-only = true;  # Show only active applications in the Dock
            };

            # Finder settings
            finder = {
              AppleShowAllExtensions = true;  # Show all file extensions in Finder
              AppleShowAllFiles = true;  # Show hidden files in Finder
              CreateDesktop = false;  # Don't show icons on the desktop
              QuitMenuItem = true;  # Add a "Quit" menu item to Finder
              ShowPathbar = true;  # Show the path bar in Finder windows
              _FXShowPosixPathInTitle = true;  # Show the full POSIX path in Finder window titles
            };

            # Global system settings
            NSGlobalDomain = {
              AppleInterfaceStyle = "Dark";  # Set dark mode for the system interface
              AppleKeyboardUIMode = 3;  # Enable full keyboard access for all controls
              InitialKeyRepeat = 10;  # Set the delay before key repeat
              KeyRepeat = 2;  # Set the key repeat rate
              NSAutomaticSpellingCorrectionEnabled = false;  # Disable automatic spelling correction
              "com.apple.swipescrolldirection" = false;  # Disable natural scrolling direction
              "com.apple.trackpad.scaling" = 2.0;  # Set trackpad scaling (speed)
            };
          };

      homebrew = {
          enable = true;
          global.autoUpdate = false;

          onActivation = {
            # "zap" removes manually installed brews and casks
            cleanup = "zap";
            autoUpdate = false;
            upgrade = false;
          };

          brews = [
          ];

          casks = [
            "jetbrains-toolbox"
            # utilities
            "aldente" # battery management
            # "macfuse" # file system utilities
            # "karabiner-elements" # keyboard remap
            "nikitabobko/tap/aerospace" # tiling window manager

            # virtualization
            # "docker" # docker desktop

            "sf-symbols" # patched font for sketchybar
            "time-out" # blurs screen every x mins
            "keycastr" # show keystrokes on screen
            "obsidian" # note taking
            "zed" # vim like editor
            "steam"
            "google-chrome"
          ];
          

          taps = [
            # default
            "homebrew/bundle"
            "homebrew/services"
          ];
        };
        })
      ];
    };

    # Expose the package set for convenience
    darwinPackages = self.darwinConfigurations."${host}".pkgs;
  };
}