{
  lib,
  pkgs,
  ...
}: let
  modulesLib = import ../lib.nix lib;

  inherit (lib.lists) findFirst sublist last;
  inherit (lib.strings) hasPrefix;
  inherit (lib) concatStringsSep types;
  inherit (modulesLib) mkArgs defaultArgReducer;
in {
  argsCreate = serviceName: cfg: let
    network =
      if cfg.args.network != null
      then "--network=${cfg.args.network}"
      else "";

    jwtSecret =
      if cfg.args.jwt-secret != null
      then ''--jwt-secret="%d/jwt-secret"''
      else "";

    keymanagerTokenFile =
      if cfg.args.keymanager.token-file != null
      then ''--keymanager-token-file="%d/keymanager-token-file"''
      else "";

    trustedNodeUrl =
      if cfg.args.trusted-node-url != null
      then ''--trusted-node-url="${cfg.args.trusted-node-url}"''
      else "";

    backfilling =
      if cfg.args.trusted-node-url != null
      then ''--backfill=${lib.boolToString cfg.args.backfill}''
      else "";

    web3Url =
      if cfg.args.web3-urls != null
      then ''--web3-url=${concatStringsSep " --web3-url=" cfg.args.web3-urls}''
      else "";

    web3SignerUrls = lib.pipe cfg.args.web3-signer-url [
      (builtins.map (x: "--web3-signer-url=${x}"))
      (builtins.concatStringsSep " ")
    ];

    payloadBuilder =
      if cfg.args.payload-builder.enable
      then "--payload-builder=true --payload-builder-url=${cfg.args.payload-builder.url}"
      else "";

    dataDirPath = "%S/${serviceName}";
    dataDir = ''--data-dir="${dataDirPath}"'';
  in rec {
    beaconNodeArgs = let
      # generate args
      args = let
        opts = import ./args.nix lib;

        pathReducer = path: let
          p =
            if (last path == "enable")
            then sublist 0 ((builtins.length path) - 1) path
            else path;
        in "--${concatStringsSep "-" p}";

        argFormatter = {
          opt,
          path,
          value,
          argReducer ? defaultArgReducer,
          pathReducer ? defaultArgReducer,
        }: let
          arg = pathReducer path;
        in
          if (opt.type == types.bool)
          then
            (
              if value
              then "${arg}"
              else ""
            )
          else "${arg}=${argReducer value}";
      in
        mkArgs {
          inherit opts;
          inherit (cfg) args;
          inherit argFormatter;
          inherit pathReducer;
        };
      # filter out certain args which need to be treated differently
      specialArgs = ["--network" "--jwt-secret" "--web3-urls" "--web3-signer-url" "--trusted-node-url" "--backfill" "--payload-builder" "--keymanager-token-file"];
      isNormalArg = name: (findFirst (arg: hasPrefix arg name) null specialArgs) == null;
      filteredArgs = builtins.filter isNormalArg args;
    in ''
      ${network} \
      ${web3Url} \
      ${web3SignerUrls} \
      ${payloadBuilder} \
      ${concatStringsSep " \\\n" filteredArgs} \
      ${lib.escapeShellArgs cfg.extraArgs}
    '';

    systemdPathsArgs = ''
      ${jwtSecret} \
      ${dataDir} \
      ${keymanagerTokenFile} \
    '';

    nodeSyncArgs = ''
      ${network} \
      ${trustedNodeUrl} \
      ${backfilling}
    '';

    binaryName =
      if cfg.args.network == "gnosis" || cfg.args.network == "chiado"
      then "${cfg.package}/bin/nimbus_beacon_node_gnosis"
      else "${cfg.package}/bin/nimbus_beacon_node";

    # When running trustedNodeSync after passing once, it gives an error
    # and doesn't continue to execute execStart. The problem occurs when
    # the service is restarted and execStartPre runs again. So we check
    # for the existence of a file in the folder, and that way we know if
    # Nimbus is running for the first time or not.
    trustedNodeSync =
      if cfg.args.trusted-node-url != null
      then let
        script = pkgs.writeShellScript "trustedNodeSync.sh" ''
          datadir="$1"
          shift
          if [ -f "$datadir/db/nbc.sqlite3" ]; then
            echo "skipping trustedNodeSync";
            exit 0
          else
            echo "starting trustedNodeSync";
            set -x
            ${binaryName} trustedNodeSync "$@"
          fi
        '';
      in "${script} ${dataDirPath} ${dataDir} ${nodeSyncArgs}"
      else null;

    execStartCommand =
      if cfg.argsFromFile.enable
      then ''${binaryName} ${systemdPathsArgs} $ARGS''
      else ''${binaryName} ${systemdPathsArgs} ${beaconNodeArgs}'';
  };
}
