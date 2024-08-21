{
  description = "";

  inputs = {
    # Package sets
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

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

          ({ lib, ... }: {
            nixpkgs = nixpkgsConfig;
            # systemd.services.sshd.wantedBy = lib.mkForce ["multi-user.target"];

            # Much faster than xz
            # isoImage.squashfsCompression = lib.mkDefault "zstd";

            boot.loader.grub.enable = true;
            boot.loader.grub.efiSupport = true;
            boot.loader.grub.device = "/dev/sdb"; # todo : change me once the system booted
            boot.loader.grub.efiInstallAsRemovable = true;
            boot.tmpOnTmpfs = true;

            boot.loader.systemd-boot.enable = false;
            boot.loader.efi.canTouchEfiVariables = false;
          })

        ];
      };


      formatter = flake-utils.lib.eachDefaultSystemMap (sys: nixpkgs.legacyPackages.${sys}.nixpkgs-fmt);
    };
}
