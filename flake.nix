{
  description = "PizzBuzz main site";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    theme = {
      url = "github:nanxiaobei/hugo-paper/4330c8b12aa48bfdecbcad6ad66145f679a430b3";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, theme, ... }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        themeName = (builtins.fromTOML (builtins.readFile ./hugo.toml)).theme;
        baseUrl = (builtins.fromTOML (builtins.readFile ./hugo.toml)).baseURL;
      in
      {

        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

        checks = {
          pre-commit = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
            };
          };
        };

        packages.website = pkgs.stdenv.mkDerivation {
          name = "pizzbuzz-website";
          src = ./.;
          nativeBuildInputs = [ pkgs.git pkgs.hugo ];
          configurePhase = ''
            mkdir -p "themes"
            [ -L "themes/${themeName}" ] && unlink "themes/${themeName}" || true
            ln -s ${theme} "themes/${themeName}"
          '';
          buildPhase = "${pkgs.hugo}/bin/hugo --minify --baseURL ${baseUrl}";
          installPhase = "cp -r public $out";
        };

        devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
          buildInputs = [
            pkgs.hugo
            pkgs.pre-commit
            pkgs.statix
          ];
          shellHook = ''
            echo ">"
            hugo version
            echo "Theme ${themeName}"
            mkdir -p "themes"
            [ -L "themes/${themeName}" ] && unlink "themes/${themeName}" || true
            ln -s ${theme} "themes/${themeName}"
          '';
        };
      }
    );
}
