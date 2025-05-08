{
  description = "Lorenz Leutgeb's Flake";
  inputs = {
    # This looks redundant, but actually is nice.
    # Allows to model "stable" vs. "unstable" vs. "don't care".
    # Don't forget to also adjust the URL for home-manager below
    # accordingly.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs.follows = "nixpkgs-unstable";

    garnix-lib = {
      url = "github:garnix-io/garnix-lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    compat.url = "github:edolstra/flake-compat";
    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    utils.url = "github:numtide/flake-utils";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        flake-compat.follows = "compat";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    pre-commit-hooks,
    sops,
    garnix-lib,
    ...
  }: let
    lib = nixpkgs.lib.recursiveUpdate nixpkgs.lib (import ./lib.nix {inherit (nixpkgs) lib;});

    inherit
      (lib)
      attrValues
      dirToAttrs
      nameValuePair
      mapAttrs
      mapAttrs'
      ;

    inherit
      (builtins)
      readDir
      ;

    system = "x86_64-linux";

    modules = {
      input = [
        nixpkgs.nixosModules.notDetected
        sops.nixosModules.sops
        garnix-lib.nixosModules.garnix
      ];
    };

    pkgs = import nixpkgs {
      inherit system;
    };

    host = name: preconfig: let
      result = lib.nixosSystem {
        specialArgs = {
          inherit self inputs lib;
        };
        modules =
          modules.input
          ++ [
            {
              system.stateVersion = "23.11";
              system.configurationRevision =
                pkgs.lib.mkIf (self ? rev) self.rev;
              nix.registry = {
                nixpkgs-unstable = {
                  from = {
                    id = "nixpkgs-unstable";
                    type = "indirect";
                  };
                  flake = nixpkgs-unstable;
                };
              };
              nixpkgs = {
                config.allowUnfree = true;
              };
            }
            preconfig
          ];
      };
    in
      result;
  in {
    nixosConfigurations = let dir = ./os/host; in mapAttrs (id: _: host id (import (dir + "/${id}"))) (readDir dir);

    devShells.${system}.default = pkgs.mkShell {
      inherit (self.checks.${system}.pre-commit) shellHook;
      buildInputs = self.checks.${system}.pre-commit.enabledPackages;
    };

    formatter.${system} = pkgs.writeShellApplication {
      name = "formatter";
      text = ''
        # shellcheck disable=all
        shell-hook () {
          ${self.checks.${system}.pre-commit.shellHook}
        }

        shell-hook
        pre-commit run --all-files
      '';
    };

    checks.${system} =
      {
        pre-commit = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
          };
        };
      }
      #// (mapAttrs' (name: value: nameValuePair "packages/${name}" value) self.packages.${system})
      // (mapAttrs' (name: value: nameValuePair "nixosConfigurations/${name}" value.config.system.build.toplevel) self.nixosConfigurations);
  };
}
