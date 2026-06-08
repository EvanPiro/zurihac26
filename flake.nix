{
  description = "zurihac26 flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devshell.flakeModule
      ];

      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem = {pkgs, ...}: let
        zurihac26Src = pkgs.haskellPackages.callCabal2nix "zurihac26" ./. {};
        zurihac26 = pkgs.haskell.lib.dontCheck zurihac26Src;
      in {
        packages.default = zurihac26;

        checks.default = pkgs.haskell.lib.doCheck zurihac26Src;

        apps.default = {
          type = "app";
          program = "${zurihac26}/bin/zurihac26";
        };

        devshells.default = {
          devshell.packages = with pkgs; [
            cabal-install
            fd
            fourmolu
            haskell-language-server
            haskellPackages."cabal-fmt"
            alejandra
          ];
          devshell.packagesFrom = [zurihac26Src];

          commands = [
            {
              name = "format";
              help = "Format Haskell, Cabal, and Nix files";
              command = ''
                fd --extension hs . app src test -x fourmolu --mode inplace {}
                cabal-fmt --inplace zurihac26.cabal
                fd --extension nix . -x alejandra {}
              '';
            }
          ];
        };
      };
    };
}
