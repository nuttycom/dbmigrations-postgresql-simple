# SPDX-FileCopyrightText: 2021 Serokell <https://serokell.io/>
#
# SPDX-License-Identifier: CC0-1.0

{
  description = "My haskell application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        haskellPackages = pkgs.haskellPackages;

        jailbreakUnbreak = pkg:
          pkgs.haskell.lib.doJailbreak (pkg.overrideAttrs (_: { meta = { }; }));

        packageName = "dbmigrations-postgresql-simple";

        dbmigrations_src = pkgs.fetchFromGitHub {
          owner = "nuttycom";
          repo = "dbmigrations";
          rev = "e7e7b3090e955d237e785b5afa652f4153224392";
          hash = "sha256-gPBdRt6QcxkEd9zZ+y5DOHheK778bQET12hNCrSYqfE=";
        };

        dbmigrations_new = haskellPackages.callCabal2nix "dbmigrations" dbmigrations_src {};
      in {
        packages.${packageName} =
          haskellPackages.callCabal2nix packageName self rec {
            dbmigrations = dbmigrations_new;
          };

        defaultPackage = self.packages.${system}.${packageName};

        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            haskellPackages.haskell-language-server # you must build it with your ghc to work
            ghcid
            cabal-install
          ];
          inputsFrom = builtins.attrValues self.packages.${system};
        };
      });
}
