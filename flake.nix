{
  description = "";

  inputs = {
    # Package sets
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zls = {
      url = "github:zigtools/zls";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # zig-overlay.follows = "zig-overlay";
      };
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , ...
    }@inputs:
    let
      # Configuration for `nixpkgs`
      nixpkgsConfig = {
        config = { allowUnfree = true; };
        overlays = [
          inputs.zig-overlay.overlays.default

          (final: prev: {
            zls = inputs.zls.packages.${prev.system}.default;
          })
        ];
      };
    in
    {
      # usb drive
      nixosConfigurations.portable = nixpkgs.lib.nixosSystem {
        system = flake-utils.lib.system.x86_64-linux;
        modules = [
          "${nixpkgs}/nixos/modules/profiles/all-hardware.nix"

          inputs.disko.nixosModules.disko

          ./disko.nix
          # Main `nix-darwin` config
          ./configuration.nix

          {
            nixpkgs = nixpkgsConfig;
          }
        ];
      };


      formatter = flake-utils.lib.eachDefaultSystemMap (sys: nixpkgs.legacyPackages.${sys}.nixpkgs-fmt);
    };
}
