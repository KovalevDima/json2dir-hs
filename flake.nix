{
  description = "clickhouse-proxy";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
  };

  outputs = {self, flake-parts, nixpkgs, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.haskell-flake.flakeModule
      ];
      perSystem = {self', pkgs, config, lib, ...}:
      let
        mapMergeAttrsList = f: x: lib.mergeAttrsList (map f x);
      in
      {
        haskellProjects = {
          default = {
            autoWire = ["packages" "apps"];
            defaults =  {
              devShell.tools = hp: {
                ghcide = null;
                cabal-install = pkgs.cabal-install;
                haskell-language-server = pkgs.haskell-language-server;
              };
            };
          };
          "static" =
            import ./contribution/project.nix {
              inherit pkgs inputs;
              isStatic = true;
            };
        };
        devShells = {
          default = pkgs.mkShell {
            inputsFrom = [ config.haskellProjects.default.outputs.devShell ];
            packages = [];
          };
        };
      };
    };
}