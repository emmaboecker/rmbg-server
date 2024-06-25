{ lib, fenix, nixpkgs, system, ... }:
let
  toolchain = fenix.packages.${system}.minimal.toolchain;
  pkgs = nixpkgs.legacyPackages.${system};
in
  (pkgs.makeRustPlatform {
    cargo = toolchain;
    rustc = toolchain;
  }).buildRustPackage {
    pname = "rmbg-server";
    version = (builtins.fromTOML (builtins.readFile ../Cargo.toml)).package.version;
    src = ../.;
    cargoLock.lockFile = ../Cargo.lock;
    meta = with lib; {
      description = "Remove Background Server";
      homepage = "https://github.com/emmaboecker/rmbg-server";
      license = licenses.agpl3Only;
    };

    buildInputs = [
      onnxruntime
    ];

    ORT_LIB_LOCATION="${pkgs.onnxruntime}/lib/";
  }