{
  description = "PostgreSQL backend for dbmigrations that relies on postgresql-simple";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    dbmigrations.url = "github:nuttycom/dbmigrations/74ef9388b45ae73a1d9c737d9644e076fe832672";
  };

  outputs = { self, nixpkgs, flake-utils, dbmigrations }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkg-name = "dbmigrations-postgresql";
          pkgs = import nixpkgs {
            inherit system;
          };

          haskell = pkgs.haskellPackages;

          haskell-overlay = final: prev: {
            dbmigrations = dbmigrations.defaultPackage.${system};
            ${pkg-name} = hspkgs.callCabal2nix pkg-name ./. {};
          };

          hspkgs = haskell.override {
            overrides = haskell-overlay;
          };
      in {
        packages = pkgs;

        defaultPackage = hspkgs.${pkg-name};

        devShell = hspkgs.shellFor {
          packages = p: [p.${pkg-name}];
          root = ./.;
          withHoogle = true;
          buildInputs = with hspkgs; [
            haskell-language-server
            cabal-install
          ];
        };
      }
    );
}
