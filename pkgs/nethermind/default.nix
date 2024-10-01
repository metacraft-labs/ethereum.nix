{
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  lib,
  lz4,
  rocksdb,
  snappy,
  stdenv,
  writeShellScriptBin,
  zstd,
}: let
  self = buildDotnetModule rec {
    pname = "nethermind";
    version = "1.28.0";

    src = fetchFromGitHub {
      owner = "NethermindEth";
      repo = pname;
      rev = version;
      hash = "sha256-kiWx2Jd5tzXnbUGhPJ7FM4BAj9O7bnNQtDFrKG3NcpI=";
    };

    buildInputs = [
      lz4
      snappy
      stdenv.cc.cc.lib
      zstd
    ];

    runtimeDeps = [
      rocksdb
      snappy
    ];

    # patches = [
    #   ./001-Remove-Commit-Fallback.patch
    # ];

    projectFile = "src/Nethermind/Nethermind.sln";
    nugetDeps = ./nuget-deps.nix;

    executables = [
      "nethermind-cli"
      "nethermind"
    ];

    dotnet-sdk = dotnetCorePackages.sdk_8_0_1xx;
    dotnet-runtime = dotnetCorePackages.aspnetcore_8_0;

    passthru = {
      # buildDotnetModule's `fetch-deps` uses `writeShellScript` instead of writeShellScriptBin making nix run .#nethermind.fetch-deps command to fail
      # This alias solves that issue. On parent folder, we only need to run this command to produce a new nuget-deps.nix file with updated deps:
      # $ nix run .#nethermind.fetch-nethermind-deps $PRJ_ROOT/pkgs/nethermind/nuget-deps.nix
      fetch-nethermind-deps = writeShellScriptBin "fetch-nethermind-deps" ''${self.fetch-deps} $@'';
    };

    meta = {
      description = "A robust execution client for Ethereum node operators";
      homepage = "https://www.nethermind.io/nethermind-client";
      license = lib.licenses.gpl3Only;
      mainProgram = "Nethermind.Runner";
      platforms = ["x86_64-linux"];
    };
  };
in
  self
