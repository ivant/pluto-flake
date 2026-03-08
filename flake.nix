{
  description = "Development environment with Julia";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        julia = pkgs.julia-bin.withPackages [
          "SimplePlutoInclude"
        ];
        mtjulia = pkgs.writeShellApplication {
          name = "mtjulia";
          text = ''
            ${julia}/bin/julia -t 12,4 --gcthreads=8,1 -O3 --heap-size-hint=32GB -C apple-latest "$@"
          '';
        };

        pluto = pkgs.writeShellApplication {
          name = "pluto";
          text = ''
            ${mtjulia}/bin/mtjulia -e 'import Pkg; Pkg.activate("."); Pkg.add("Pluto"); import Pluto; Pluto.run()'
          '';
        };
      in
      {
        packages.default = pluto;

        apps.default = {
          type = "app";
          program = "${mtjulia}/bin/mtjulia";
        };

        apps.mtjulia = {
          type = "app";
          program = "${mtjulia}/bin/mtjulia";
        };

        apps.pluto = {
          type = "app";
          program = "${pluto}/bin/pluto";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            julia
            cmdstan
          ];

          shellHook = ''
            echo "Julia development environment"
            echo "Julia version: $(julia --version)"
          '';
        };
      });
}
