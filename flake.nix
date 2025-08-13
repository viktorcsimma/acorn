{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    agda2hs.url = "github:stites/agda2hs/acorn";
    nixpkgs.follows = "agda2hs/nixpkgs";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: rec {
        packages = let
            agda2hs-lib = inputs'.agda2hs.packages.agda2hs-lib;
            agda-packages = [
              agda2hs-lib
              pkgs.agdaPackages.cubical
              pkgs.agdaPackages.standard-library
            ];
            agda2hs = inputs.agda2hs.lib.${system}.withPackages agda-packages;
            agda-with-packages = pkgs.agda.withPackages (ps: agda-packages);
          in {
            inherit agda2hs agda-with-packages;
        };
        devShells.default = with packages; pkgs.haskellPackages.shellFor {
          packages = p: [];
          buildInputs = with pkgs.haskellPackages; [
            self'.packages.agda2hs
            self'.packages.agda-with-packages
            cabal-install
            cabal2nix
            haskell-language-server
          ];
        };
      };
    };
}
