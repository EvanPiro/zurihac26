{
  description = "zurihac26 flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem = { pkgs, ... }:
        let
          zurihac26Src = pkgs.haskellPackages.callCabal2nix "zurihac26" ./. { };
          zurihac26 = pkgs.haskell.lib.dontCheck zurihac26Src;
        in
        {
          packages.default = zurihac26;

          checks.default = pkgs.haskell.lib.doCheck zurihac26Src;

          apps.default = {
            type = "app";
            program = "${zurihac26}/bin/zurihac26";
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              ghc
              cabal-install
              haskell-language-server
            ];
          };
        };
    };
}
