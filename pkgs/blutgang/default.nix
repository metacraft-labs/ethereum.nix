{
  lib,
  fetchFromGitHub,
  openssl,
  pkg-config,
  rustPlatform,
  rust-jemalloc-sys,
  stdenv,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "blutgang";
  version = "0.3.6";

  src = fetchFromGitHub {
    owner = "rainshowerLabs";
    repo = pname;
    rev = "Blutgang-${version}";
    hash = "sha256-EAmmCvESMneYuoTEa8Qm5eYqJkkRDY8CqlfsER1Pq8s=";
  };

  cargoHash = "sha256-JnUYPSsMQ4blE31L1c4R7QikUZ9k/XMqnuzeNNtjUVU=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs =
    [openssl rust-jemalloc-sys]
    ++ lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.Security
      darwin.apple_sdk.frameworks.SystemConfiguration
    ];

  meta = {
    description = "The wd40 of ethereum load balancers";
    homepage = "https://github.com/rainshowerLabs/blutgang";
    # Functional Source License, Version 1.0, Apache 2.0 Change License
    # https://github.com/rainshowerLabs/blutgang/blob/Blutgang-0.3.6/LICENSE
    license = lib.licenses.unfree;
    mainProgram = "blutgang";
    platforms = ["x86_64-linux" "aarch64-darwin"];
  };
}
