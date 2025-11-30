{
  outputs = {
    rust-overlay,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          rust-overlay.overlays.default
        ];
      };
      inherit (pkgs) lib;
      inherit (lib) length;

      toolchain = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
      rust-analyzer = pkgs.rust-bin.selectLatestNightlyWith (t: t.rust-analyzer);
    in {
      legacyPackages = pkgs;
      devShells.default = let
        inherit (pkgs.lib) makeLibraryPath concatStringsSep makeSearchPath optionalAttrs foldl' recursiveUpdate;
        lib_deps = with pkgs; [];
        hasLibraryDeps = length lib_deps > 0;
      in
        pkgs.mkShell {
          nativeBuildInputs = with pkgs;
            [
              pkg-config
              neovim
              just
            ]
            ++ [toolchain rust-analyzer];

          buildInputs =
            [
            ]
            ++ lib_deps;

          env = foldl' recursiveUpdate {} [
            {RUST_SRC_PATH = "${toolchain.passthru.availableComponents.rust-src}/lib/rustlib/src/rust/library";}
            (optionalAttrs hasLibraryDeps {
              LD_LIBRARY_PATH = makeLibraryPath lib_deps;
              PKG_CONFIG_PATH = concatStringsSep ":" [
                (makeSearchPath "lib/pkgconfig" lib_deps)
                (makeSearchPath "share/pkgconfig" lib_deps)
              ];
            })
          ];
        };
    });

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };
}
