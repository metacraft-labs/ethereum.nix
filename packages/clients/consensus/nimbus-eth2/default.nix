{
  stdenv,
  fetchFromGitHub,
  darwin,
  lib,
  #  git,
  nim,
  cmake,
  which,
  writeScriptBin,
  # Options: nimbus_light_client, nimbus_validator_client, nimbus_signing_node
  makeTargets ? ["all"],
  # These are the only platforms tested in CI and considered stable.
  stablePlatforms ? [
    "x86_64-linux"
    "aarch64-linux"
    "armv7a-linux"
    "x86_64-darwin"
    "aarch64-darwin"
    "x86_64-windows"
  ],
}:
# Version 1.6.12 is known to be stable and overriden in top-level.
assert nim.version == "1.6.12";
  stdenv.mkDerivation rec {
    pname = "nimbus";
    rev = "1bc9f3a67ac519ab4f889ca19abfd74f5e07c205";
    version = "23.6.0";

    src = fetchFromGitHub {
      owner = "status-im";
      repo = "nimbus-eth2";
      inherit rev;
      hash = "sha256-uAaKKLMlQRklUfTyYmdwI+27evmEEGVE2TFkKuCgAes=";
      fetchSubmodules = true;
    };

    # Fix for Nim compiler calling 'git rev-parse' and 'lsb_release'.
    nativeBuildInputs = let
      fakeGit = writeScriptBin "git" "echo $commit";
      fakeLsbRelease = writeScriptBin "lsb_release" "echo nix";
    in
      [fakeGit fakeLsbRelease nim which cmake]
      ++ lib.optionals stdenv.isDarwin [darwin.cctools];

    enableParallelBuilding = true;

    # Disable CPU optmizations that make binary not portable.
    NIMFLAGS = "-d:disableMarchNative -d:git_revision_override=${rev}";

    makeFlags = makeTargets ++ ["USE_SYSTEM_NIM=1"];

    # Generate the nimbus-build-system.paths file.
    configurePhase = ''
      patchShebangs scripts vendor/nimbus-build-system/scripts
      make nimbus-build-system-paths
    '';

    installPhase = ''
      mkdir -p $out/bin
      rm build/generate_makefile
      cp build/* $out/bin
    '';

    meta = with lib; {
      homepage = "https://nimbus.guide/";
      downloadPage = "https://github.com/status-im/nimbus-eth2/releases";
      changelog = "https://github.com/status-im/nimbus-eth2/blob/stable/CHANGELOG.md";
      description = "Nimbus is a lightweight client for the Ethereum consensus layer";
      longDescription = ''
        Nimbus is an extremely efficient consensus layer client implementation.
        While it's optimised for embedded systems and resource-restricted devices --
        including Raspberry Pis, its low resource usage also makes it an excellent choice
        for any server or desktop (where it simply takes up fewer resources).
      '';
      branch = "capella-eip4844-local-sim";
      license = with licenses; [asl20 mit];
      maintainers = with maintainers; [jakubgs];
      platforms = stablePlatforms;
    };
  }
