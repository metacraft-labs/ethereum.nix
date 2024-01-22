{
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  lib,
  lz4,
  rocksdb,
  snappy,
  stdenv,
  zstd,
  writeShellScriptBin,
}: let
  self = buildDotnetModule rec {
    pname = "nethermind";
    version = "1.25.1";

    src = fetchFromGitHub {
      owner = "NethermindEth";
      repo = pname;
      rev = version;
      hash = "sha256-h46+cM20e5ztBSdimOR39tcNcG9/RU1NY/lS8Rwm9Xs=";
      fetchSubmodules = true;
    };

    buildInputs = [
      lz4
      snappy
      stdenv.cc.cc.lib
      zstd
    ];

    fakeGit = writeShellScriptBin "git" "echo ${version}";
    nativeBuildInputs = [fakeGit];

    runtimeDeps = [
      rocksdb
      snappy
    ];

    patches = [
      ./001-Remove-Commit-Fallback.patch
    ];

    projectFile = "src/Nethermind/Nethermind.sln";
    nugetDeps = ./nuget-deps.nix;

    executables = [
      "nethermind-cli"
      "nethermind"
    ];

    dotnet-sdk = dotnetCorePackages.sdk_8_0;
    dotnet-runtime = dotnetCorePackages.aspnetcore_8_0;

    passthru = rec {
      # buildDotnetModule's `fetch-deps` uses `writeShellScript` instead of writeShellScriptBin making nix run .#nethermind.fetch-deps command to fail
      # This alias solves that issue. On parent folder, we only need to run this command to produce a new nuget-deps.nix file with updated deps:
      # $ nix run .#nethermind.fetch-nethermind-deps $PRJ_ROOT/packages/clients/execution/nethermind/nuget-deps.nix
      fetch-nethermind-deps = writeShellScriptBin "fetch-nethermind-deps" ''${self.fetch-deps} $@'';
    };

    meta = {
      description = "Our flagship Ethereum client for Linux, Windows, and macOS—full and actively developed";
      homepage = "https://nethermind.io/nethermind-client";
      license = lib.licenses.gpl3;
      mainProgram = "nethermind";
      platforms = ["x86_64-linux"];
    };
  };
in
  self
