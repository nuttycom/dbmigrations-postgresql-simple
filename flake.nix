{
  description = "PostgreSQL backend for dbmigrations that relies on postgresql-simple";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    dbmigrations = {
      url = "github:haskell-github-trust/dbmigrations/6d641f169b60ecb9e9de6e7e82d4bafbcaac62ff";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, dbmigrations }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkg-name = "dbmigrations-postgresql-simple";
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ dbmigrations.overlays.default ];
        };

        hspkgs = pkgs.haskellPackages.extend (hfinal: hprev: {
          ${pkg-name} = hfinal.callCabal2nix pkg-name ./. {};
        });
      in {
        packages = {
          ${pkg-name} = hspkgs.${pkg-name};
          default = self.packages.${system}.${pkg-name};
        };

        overlays.default = final: prev: {
          haskellPackages = prev.haskellPackages.extend (hfinal: hprev: {
            ${pkg-name} = hfinal.callCabal2nix pkg-name ./. {};
          });
        };

        devShells.default = hspkgs.shellFor {
          packages = p: [p.${pkg-name}];
          withHoogle = true;
          buildInputs = with hspkgs; [
            cabal-install
          ];
        };
      }
    );
}
