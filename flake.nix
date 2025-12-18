{
  description = "Personal Darwin system flake with home-manager";

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
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Pin homebrew repos for reproducible builds
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs@{ self, darwin, nixpkgs, home-manager, nix-homebrew, homebrew-core, homebrew-cask }:
  let
    system = "aarch64-darwin";  # ARM-based macOS (Apple Silicon)
    pkgs = nixpkgs.legacyPackages.${system};
    # Read from environment (requires --impure flag)
    # Fallback needed because nix daemon runs as root
    envUser = builtins.getEnv "USER";
    envHost = builtins.getEnv "HOSTNAME";
    user = if envUser == "" || envUser == "root" then builtins.getEnv "SUDO_USER" else envUser;
    host = if envHost == "" then "macbook" else envHost;
  in
  {
    darwinConfigurations."${host}" = darwin.lib.darwinSystem {
      inherit system;
      modules = [
        # ===== HOME MANAGER CONFIGURATION =====
        home-manager.darwinModules.home-manager
        {
          home-manager.backupFileExtension = "backup";
          home-manager.useGlobalPkgs = true;      # Use system nixpkgs instead of private
          home-manager.useUserPackages = true;    # Install packages to /etc/profiles
          home-manager.users.${user} = { pkgs, ... }: {
            home.stateVersion = "24.05";

            # ----- Git Configuration -----
            programs.git = {
              enable = true;
              ignores = [
                ".DS_Store"           # macOS folder metadata
                "*.swp"               # Vim swap files
                ".direnv"             # direnv cache
                ".devenv"             # devenv cache
                ".envrc.local"        # Local direnv overrides
              ];
              settings = {
                user.name = "sidux";
                user.email = "ahmed.lebbada@gmail.com";
                core.editor = "vim";
                color.ui = true;
                init.defaultBranch = "main";
                pull.rebase = true;                # Rebase on pull instead of merge
                push.autoSetupRemote = true;       # Auto setup remote tracking branch
                fetch.prune = true;                # Auto prune deleted remote branches
                rerere.enabled = true;             # Remember merge conflict resolutions
                diff.algorithm = "histogram";      # Better diff algorithm
                merge.conflictstyle = "zdiff3";    # Better conflict markers
                rebase.autoStash = true;           # Auto stash before rebase
              };
            };

            # ----- Delta (better git diffs) -----
            programs.delta = {
              enable = true;
              enableGitIntegration = true;         # Integrate with git
              options = {
                navigate = true;                   # n/N to jump between files
                side-by-side = true;
                line-numbers = true;
              };
            };

            # ----- Fish Shell Configuration -----
            programs.fish = {
              enable = true;
              interactiveShellInit = ''
                set fish_greeting                  # Disable greeting message
                starship init fish | source       # Cross-shell prompt
                zoxide init fish | source         # Smart cd that learns your habits
                fzf --fish | source               # Fuzzy finder keybindings (Ctrl+R, Ctrl+T)
                direnv hook fish | source         # Per-directory environments
                fish_add_path ~/Library/flutter/bin
                fish_add_path ~/.local/bin
              '';
              shellAliases = {
                # Modern CLI replacements
                ll = "eza -l --icons --git";      # ls with git status
                la = "eza -la --icons --git";
                lt = "eza --tree --icons -L 2";   # Tree view (2 levels)
                cat = "bat";                       # Syntax highlighted cat
                # Git shortcuts
                g = "git";
                gs = "git status";
                gd = "git diff";
                gds = "git diff --staged";
                gp = "git push";
                gl = "git pull";
                gco = "git checkout";
                gcb = "git checkout -b";
                lg = "lazygit";                    # Full git TUI
                # Nix shortcuts
                nix-build = "~/dotfiles/setup.sh"; # Build and apply nix config
                nix-update = "nix flake update --flake ~/dotfiles";  # Update flake inputs
                # Navigation
                ".." = "cd ..";
                "..." = "cd ../..";
              };
            };

            # ----- Starship Prompt -----
            programs.starship = {
              enable = true;
              settings = {
                add_newline = false;               # Compact prompt
                command_timeout = 1000;            # Timeout for slow commands
                docker_context.format = "";        # Hide docker context (noisy)
                character = {
                  success_symbol = "[➜](bold green)";
                  error_symbol = "[➜](bold red)";
                };
                directory = {
                  truncation_length = 3;           # Show last 3 dirs
                  truncate_to_repo = true;         # Truncate to git root
                };
                git_status = {
                  ahead = "⇡\${count}";
                  behind = "⇣\${count}";
                  diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
                };
              };
            };

            # ----- Modern CLI Tools (via home-manager) -----
            programs.zoxide.enable = true;         # Smart cd that learns your habits
            programs.fzf = {
              enable = true;                       # Fuzzy finder for files, history, etc
              enableFishIntegration = true;
              defaultOptions = [ "--height 40%" "--border" ];
            };
            programs.ripgrep.enable = true;        # Fast recursive grep (rg)
            programs.eza = {
              enable = true;                       # Modern ls replacement
              enableFishIntegration = true;
              git = true;                          # Show git status in listings
              icons = "auto";
            };
            programs.fd = {
              enable = true;                       # Fast find alternative
              ignores = [ ".git" "node_modules" ".direnv" ".devenv" ];
            };
            programs.bat = {
              enable = true;                       # Cat with syntax highlighting
              config = {
                theme = "TwoDark";
                style = "numbers,changes";         # Show line numbers and git changes
              };
            };
            programs.lazygit.enable = true;        # Terminal UI for git

            # ----- Development Tools -----
            programs.direnv = {
              enable = true;                       # Per-directory environment variables
              nix-direnv.enable = true;            # Faster nix integration
            };

            programs.gh = {
              enable = true;                       # GitHub CLI
              settings = {
                git_protocol = "ssh";              # Use SSH for git operations
                prompt = "enabled";
              };
            };

            programs.tmux = {
              enable = true;                       # Terminal multiplexer
              shell = "${pkgs.fish}/bin/fish";
              terminal = "tmux-256color";
              historyLimit = 10000;
              keyMode = "vi";                      # Vi-style keybindings
              prefix = "C-a";                      # Ctrl+a instead of Ctrl+b
              extraConfig = ''
                # Enable mouse support
                set -g mouse on
                # Start windows and panes at 1, not 0
                set -g base-index 1
                setw -g pane-base-index 1
                # Renumber windows when one is closed
                set -g renumber-windows on
              '';
            };

            programs.atuin = {
              enable = true;                       # Magical shell history
              enableFishIntegration = true;
              settings = {
                auto_sync = false;                 # Disable cloud sync by default
                search_mode = "fuzzy";
                filter_mode = "global";
              };
            };

            programs.htop = {
              enable = true;                       # Interactive process viewer
              settings = {
                show_program_path = false;
                tree_view = true;
              };
            };

            fonts.fontconfig.enable = true;        # Enable fontconfig for Nerd Fonts
          };
        }

        # ===== NIX-HOMEBREW CONFIGURATION =====
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;                  # Intel homebrew under Rosetta 2
            user = "${user}";
            autoMigrate = true;                    # Migrate existing installations
          };
        }

        # ===== SYSTEM-WIDE CONFIGURATION =====
        ({ pkgs, ... }: {
          nix.package = pkgs.nixVersions.stable;
          nixpkgs.hostPlatform = "aarch64-darwin";
          nixpkgs.config.allowUnfree = true;       # Allow proprietary software
          nix.enable = true;

          nix.settings = {
            experimental-features = [ "nix-command" "flakes" ];
            trusted-users = [ "root" "${user}" ];
            max-jobs = "auto";                     # Use all CPU cores
            build-users-group = "nixbld";
            nix-path = [];                         # Disable legacy channels (using flakes)
            extra-nix-path = "nixpkgs=flake:nixpkgs";
            # Binary caches for faster builds
            substituters = [
              "https://cache.nixos.org"
              "https://devenv.cachix.org"
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
            ];
            keep-outputs = true;                   # Keep build outputs for debugging
            keep-derivations = true;               # Keep .drv files for nix-shell
            warn-dirty = false;                    # Don't warn about dirty git trees
          };

          nix.extraOptions = ''
            upgrade-nix-store-path-url = "https://install.determinate.systems/nix-upgrade/stable/universal"
          '';

          # Automatic maintenance
          nix.gc = {
            automatic = true;                      # Run garbage collection automatically
            interval = { Weekday = 0; Hour = 2; Minute = 0; };  # Sunday 2am
            options = "--delete-older-than 30d";   # Delete generations older than 30 days
          };
          nix.optimise.automatic = true;           # Optimise store (dedup)

          system.stateVersion = 5;
          system.primaryUser = user;            # Required for user-specific settings

          # ----- System Packages -----
          # Note: htop, gh, delta, starship are installed via home-manager programs
          environment.systemPackages = with pkgs; [
            # === Monitoring ===
            btop                                   # Modern resource monitor with graphs

            # === Development Tools ===
            devenv                                 # Declarative developer environments
            jq                                     # JSON processor
            yq-go                                  # YAML processor (like jq for YAML)
            nodejs_22                              # Node.js LTS runtime
            nixpkgs-fmt                            # Nix code formatter
            nixfmt-rfc-style                       # Alternative nix formatter (RFC style)
            git-lfs                                # Git extension for large files
            tldr                                   # Simplified man pages with examples
            tree                                   # Directory tree viewer
            watchexec                              # Execute commands on file changes
            just                                   # Modern make alternative (justfile)
            mkcert                                 # Local HTTPS certificates
            httpie                                 # Modern HTTP client (like curl)

            # === Fonts ===
            jetbrains-mono                         # Coding font with ligatures
            nerd-fonts.jetbrains-mono              # Nerd Font patched version
            nerd-fonts.fira-code
            nerd-fonts.hack

            # === macOS Utilities ===
            mysides                                # Manage Finder sidebar
            stats                                  # System monitor in menu bar
            raycast                                # Spotlight replacement with extensions
            hidden-bar                             # Hide menu bar icons
            monitorcontrol                         # Control external monitor brightness
            jankyborders                           # Window borders for tiling WM
            uv                                     # Fast Python package/project manager
          ];

          # ----- Shell Configuration -----
          programs.direnv = {
            enable = true;                         # Per-directory environments
            nix-direnv.enable = true;              # Cache nix-shell environments
          };

          programs.zsh.enable = true;              # macOS default shell

          programs.fish = {
            enable = true;
            useBabelfish = true;                   # Better bash compatibility
          };

          # ----- User Configuration -----
          users.users.${user} = {
            name = user;
            home = "/Users/${user}";
            shell = pkgs.fish;                     # Default shell
          };

          users.users.root.home = "/var/root";     # macOS default for root

          environment.shells = with pkgs; [ fish zsh ];

          # ----- Security -----
          security.pam.services.sudo_local.touchIdAuth = true;  # Touch ID for sudo

          # ----- Keyboard -----
          system.keyboard = {
            enableKeyMapping = true;
            remapCapsLockToEscape = true;          # Caps Lock → Escape (great for vim)
          };

          # ----- macOS System Preferences -----
          system.defaults = {
            # Mouse
            ".GlobalPreferences"."com.apple.mouse.scaling" = 4.0;  # Mouse speed

            # Spaces
            spaces.spans-displays = true;          # Spaces span all displays

            # Dock
            dock = {
              autohide = true;                     # Auto-hide dock
              autohide-delay = 0.0;                # No delay before showing
              autohide-time-modifier = 0.0;        # Instant show/hide animation
              orientation = "bottom";
              tilesize = 50;
              magnification = true;                # Magnify icons on hover
              largesize = 64;                      # Magnified icon size
              static-only = true;                  # Only show running apps
              show-recents = false;                # Don't show recent apps
              mru-spaces = false;                  # Don't reorder spaces based on use
              # Hot corners (1=disabled, 2=Mission Control, 3=App Windows, 4=Desktop, 5=Screen Saver, 11=Launchpad, 13=Lock)
              wvous-tl-corner = 2;                 # Top-left: Mission Control (show all windows)
              wvous-tr-corner = 1;                 # Top-right: disabled
              wvous-bl-corner = 1;                 # Bottom-left: disabled
              wvous-br-corner = 1;                 # Bottom-right: disabled
            };

            # Finder
            finder = {
              AppleShowAllExtensions = true;       # Show all file extensions
              AppleShowAllFiles = true;            # Show hidden files
              CreateDesktop = false;               # Don't show icons on desktop
              FXDefaultSearchScope = "SCcf";       # Search current folder by default
              FXEnableExtensionChangeWarning = false;  # No warning when changing extension
              FXPreferredViewStyle = "Nlsv";       # List view by default
              QuitMenuItem = true;                 # Allow quitting Finder
              ShowPathbar = true;                  # Show path bar
              ShowStatusBar = true;                # Show status bar
              _FXShowPosixPathInTitle = true;      # Full path in window title
              _FXSortFoldersFirst = true;          # Folders on top when sorting
            };

            # Login window
            loginwindow = {
              GuestEnabled = false;                # Disable guest account
            };

            # Screenshots
            screencapture = {
              location = "~/Pictures/screenshots";
              type = "png";                        # PNG format
              disable-shadow = true;               # No window shadow in screenshots
            };

            # Trackpad
            trackpad = {
              Clicking = true;                     # Tap to click
              TrackpadRightClick = true;           # Two-finger right click
              TrackpadThreeFingerDrag = true;      # Three-finger drag
            };

            # Global settings
            NSGlobalDomain = {
              AppleInterfaceStyle = "Dark";        # Dark mode
              AppleKeyboardUIMode = 3;             # Full keyboard access in dialogs
              ApplePressAndHoldEnabled = false;    # Disable press-and-hold for key repeat
              InitialKeyRepeat = 10;               # Delay before key repeat (lower = faster)
              KeyRepeat = 2;                       # Key repeat rate (lower = faster)
              NSAutomaticCapitalizationEnabled = false;
              NSAutomaticDashSubstitutionEnabled = false;
              NSAutomaticPeriodSubstitutionEnabled = false;
              NSAutomaticQuoteSubstitutionEnabled = false;
              NSAutomaticSpellingCorrectionEnabled = false;
              NSDocumentSaveNewDocumentsToCloud = false;  # Don't save to iCloud by default
              NSNavPanelExpandedStateForSaveMode = true;  # Expand save dialog by default
              NSNavPanelExpandedStateForSaveMode2 = true;
              PMPrintingExpandedStateForPrint = true;     # Expand print dialog by default
              PMPrintingExpandedStateForPrint2 = true;
              "com.apple.swipescrolldirection" = false;   # Non-natural scrolling
              "com.apple.trackpad.scaling" = 2.0;         # Trackpad speed
              "com.apple.sound.beep.feedback" = 0;        # Disable feedback sound
            };

            # Custom preferences not available in nix-darwin
            CustomUserPreferences = {
              # Disable Siri
              "com.apple.assistant.support" = {
                "Assistant Enabled" = false;
              };
              # Activity Monitor: Show all processes
              "com.apple.ActivityMonitor" = {
                ShowCategory = 0;
              };
              # TextEdit: Plain text by default
              "com.apple.TextEdit" = {
                RichText = 0;
              };
              # iTerm2: Load preferences from dotfiles
              "com.googlecode.iterm2" = {
                PrefsCustomFolder = "~/dotfiles/iterm";
                LoadPrefsFromCustomFolder = true;
              };
            };
          };

          # ----- Homebrew (for casks not in nixpkgs) -----
          homebrew = {
            enable = true;
            global.autoUpdate = false;             # Don't auto-update (managed by nix)
            caskArgs.no_quarantine = true;         # Don't quarantine downloaded apps
            caskArgs.appdir = "/Applications/Nix Apps";
            onActivation = {
              cleanup = "zap";                     # Remove unlisted packages
              autoUpdate = false;
              upgrade = false;
            };

            brews = [];

            casks = [
              # IDEs
              "jetbrains-toolbox"                  # JetBrains IDE manager

              # Utilities
              "aldente"                            # Battery charge limiter
              "nikitabobko/tap/aerospace"          # Tiling window manager
              "sf-symbols"                         # Apple SF Symbols font
              "time-out"                           # Break reminder
              "keycastr"                           # Show keystrokes on screen

              # Productivity
              "obsidian"                           # Note-taking with markdown

              # Editors
              "zed"                                # GPU-accelerated code editor

              # Personal
              "steam"                              # Gaming platform
              "google-chrome"                      # Web browser
            ];

            taps = [
              "nikitabobko/tap"                    # AeroSpace window manager
            ];
          };

          # ----- Activation Scripts -----
          system.activationScripts.postActivation.text = ''
            # Ensure nix binaries are in PATH for GUI apps (Spotlight, Alfred, etc)
            if ! grep -q "/run/current-system/sw/bin" /etc/paths; then
              echo "Adding /run/current-system/sw/bin to /etc/paths"
              echo "/run/current-system/sw/bin" | cat - /etc/paths > /tmp/paths
              mv /tmp/paths /etc/paths
            fi

            # Set Fish as default shell
            echo "Changing default shell to Fish for ${user}"
            sudo chsh -s ${pkgs.fish}/bin/fish ${user}

            # Create screenshots directory if it doesn't exist
            mkdir -p /Users/${user}/Pictures/screenshots
          '';
        })
      ];
    };

    darwinPackages = self.darwinConfigurations."${host}".pkgs;
  };
}
