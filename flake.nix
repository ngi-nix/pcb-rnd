{
  description = "(pcb-rnd is a modular PCB layout editor)";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-20.03";

  # Upstream source tree(s).
  inputs.pcb-rnd-src = { type = "tarball"; url = "http://repo.hu/projects/pcb-rnd/releases/pcb-rnd-2.2.3.tar.bz2"; flake = false; };

  outputs = { self, nixpkgs, pcb-rnd-src }:
    let

      version = "2.2.3";

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {

      # A Nixpkgs overlay.
      overlay = final: prev: {

        pcb-rnd = with final; stdenv.mkDerivation rec {
          name = "pcb-rnd-${version}";

          src = pcb-rnd-src;

          buildInputs = [ ];

          meta = {
            homepage = "http://repo.hu/projects/pcb-rnd/";
            description = "pcb-rnd is a Printed Circuit Board editor.";
          };
        };

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) pcb-rnd;
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.pcb-rnd);

      # Tests run by 'nix flake check' and by Hydra.
      checks = forAllSystems (system: {
        inherit (self.packages.${system}) pcb-rnd;

        # Additional tests, if applicable.
        test =
          with nixpkgsFor.${system};
          stdenv.mkDerivation {
            name = "pcb-rnd-test-${version}";

            buildInputs = [ pcb-rnd ];

            unpackPhase = "true";

            buildPhase = ''
              echo 'running some integration tests'
              [[ $(pcb-rnd) = 'Hello, world!' ]]
            '';

            installPhase = "mkdir -p $out";
          };

      });

    };
}
