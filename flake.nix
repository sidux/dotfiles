{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {

      nix = {
        settings = {
          experimental-features = [ "nix-command" "flakes" "repl-flake" ];
          bash-prompt-prefix = "(nix:$name)\040";
          max-jobs = "auto";
          extra-nix-path = "nixpkgs=flake:nixpkgs";
          trusted-users = [ "root" "ahmed" ];
        };
        buildMachines = [{
          hostName = "build-users-group";
          systems = [ "nixbld" ];
        }];
      };

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs; [
          git
          gh
          htop
          jq
          yq-go
          nodejs_20
          nixpkgs-fmt
          mysides
      ];

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      programs.fish.enable = true;

      programs.zsh.enable = true;  # We still need this for macOS
      environment.shells = [ pkgs.fish ];

      users.users.${builtins.getEnv "USER"} = {
        shell = pkgs.fish;
      };


      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      security.pam.enableSudoTouchIdAuth = true;
      programs.direnv.enable = true;
      programs.tmux.enableFzf = true;
      programs.vim.enable = true;
      # programs.zsh.enableFzfCompletion = true;
      # programs.zsh.enableFzfHistory = true;

    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#my_hostname
    darwinConfigurations."my_hostname" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."my_hostname".pkgs;
  };
}
