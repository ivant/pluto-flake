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
            CPUS=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)
            WORKER=$(( CPUS * 3 / 4 ))
            INTERACTIVE=$(( CPUS - WORKER ))
            GC=$(( CPUS / 2 ))
            [[ "$WORKER" -lt 1 ]] && WORKER=1
            [[ "$INTERACTIVE" -lt 1 ]] && INTERACTIVE=1
            [[ "$GC" -lt 1 ]] && GC=1
            exec ${julia}/bin/julia \
              -t "$WORKER,$INTERACTIVE" \
              --gcthreads="$GC,1" \
              -O3 \
              --heap-size-hint=75% \
              ${pkgs.lib.optionalString pkgs.stdenv.isDarwin "-C apple-latest"} \
              "$@"
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
          ];

          shellHook = ''
            echo "Julia development environment"
            echo "Julia version: $(julia --version)"
          '';
        };
      });
}
