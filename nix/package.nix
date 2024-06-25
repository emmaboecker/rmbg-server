{ rustPlatform, lib, config, ... }:
  rustPlatform.buildRustPackage {
    pname = "rmbg-server";
    version = (builtins.fromTOML (builtins.readFile ../Cargo.toml)).package.version;
    src = ../.;
    cargoLock.lockFile = ../Cargo.lock;
    meta = with lib; {
      description = config.description;
      homepage = "https://github.com/emmaboecker/rmbg-server";
      license = licenses.agpl3;
    };
  }