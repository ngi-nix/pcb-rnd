{
  description = "(pcb-rnd is a modular PCB layout editor)";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  # Upstream source tree(s).
  inputs.pcb-rnd-src = { type = "tarball"; url = "http://repo.hu/projects/pcb-rnd/releases/pcb-rnd-3.0.0.tar.bz2"; flake = false; };
  inputs.librnd-src = { type = "tarball"; url = "http://repo.hu/projects/librnd/releases/librnd-3.0.0.tar.bz2"; flake = false; };

  outputs = { self, nixpkgs, pcb-rnd-src, librnd-src }:
    let

      version = "3.0.0";

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {

      # A Nixpkgs overlay.
      overlay = final: prev: {

        pcb-rnd = with final; stdenv.mkDerivation rec {
          pname = "pcb-rnd";

          inherit version;

          src = pcb-rnd-src;

          buildInputs = [ final.librnd ];

          LIBRND_PREFIX = final.librnd;

          meta = {
            homepage = "http://repo.hu/projects/pcb-rnd/";
            description = "pcb-rnd is a Printed Circuit Board editor.";
          };
        };

        librnd = with final; stdenv.mkDerivation rec {
          pname = "librnd";

          inherit version;

          src = librnd-src;

          meta = {
            homepage = "http://repo.hu/projects/librnd/";
            description = "librnd is a modular 2d CAD framework that drives pcb-rnd and other Ringdove applications.";
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

    };
}
