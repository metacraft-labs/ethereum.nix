{
  fetchFromGitHub,
  pkgs,
  targets ? ["nimbus_beacon_node" "nimbus_validator_client" "gnosis-build" "gnosis-vc-build"],
  stableSystems ? ["x86_64-linux" "aarch64-linux"],
}: let
  version = "25.1.0";
  src = fetchFromGitHub {
    owner = "status-im";
    repo = "nimbus-eth2";
    rev = "v${version}";
    hash = "sha256-I+rDkVUk5BLxV2wNnRMHSE9Uuz9KykbVeXB40zvRZz8=";
    fetchSubmodules = true;
  };
in
  import "${src}/nix" {inherit pkgs targets stableSystems;}
