{
  config,
  lib,
  pkgs,
  ...
}: let
  modulesLib = import ../lib.nix lib;

  inherit (lib.lists) findFirst sublist last;
  inherit (lib.strings) hasPrefix;
  inherit (lib.attrsets) zipAttrsWith;
  inherit
    (lib)
    concatStringsSep
    filterAttrs
    flatten
    mapAttrs'
    mapAttrsToList
    mkIf
    mkMerge
    nameValuePair
    types
    ;
  inherit (modulesLib) mkArgs baseServiceConfig defaultArgReducer;

  eachBeacon = config.services.ethereum.nimbus-eth2;
in {
  ###### interface
  inherit (import ./options.nix {inherit lib pkgs;}) options;

  ###### implementation

  config = mkIf (eachBeacon != {}) {
    assertions =
      mapAttrsToList
      (
        name: cfg: {
          assertion = cfg.args.payload-builder.enable -> cfg.args.payload-builder.url != null;
          message = "services.ethereum.nimbus-eth2.payload-builder must have `url` specified, if enabled";
        }
      )
      eachBeacon;

    # configure the firewall for each service
    networking.firewall = let
      openFirewall = filterAttrs (_: cfg: cfg.openFirewall) eachBeacon;
      perService =
        mapAttrsToList
        (
          _: cfg:
            with cfg.args; {
              allowedUDPPorts = [udp-port];
              allowedTCPPorts = [tcp-port];
            }
        )
        openFirewall;
    in
      zipAttrsWith (_name: flatten) perService;

    systemd.services =
      mapAttrs'
      (
        beaconName: let
          serviceName = "nimbus-eth2";
        in
          cfg: let
            network =
              if cfg.args.network != null
              then "--network=${cfg.args.network}"
              else "";

            jwtSecret =
              if cfg.args.jwt-secret != null
              then ''--jwt-secret="%d/jwt-secret"''
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

            payloadBuilder =
              if cfg.args.payload-builder.enable
              then "--payload-builder=true --payload-builder-url=${cfg.args.payload-builder.url}"
              else "";

            dataDirPath = "%S/${serviceName}";
            dataDir = ''--data-dir="${dataDirPath}"'';

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
              specialArgs = ["--network" "--jwt-secret" "--web3-urls" "--trusted-node-url" "--backfill" "--payload-builder"];
              isNormalArg = name: (findFirst (arg: hasPrefix arg name) null specialArgs) == null;
              filteredArgs = builtins.filter isNormalArg args;
            in ''
              ${network} ${jwtSecret} \
              ${web3Url} \
              ${dataDir} \
              ${payloadBuilder} \
              ${concatStringsSep " \\\n" filteredArgs} \
              ${lib.escapeShellArgs cfg.extraArgs}
            '';

            nodeSyncArgs = ''
              ${network} \
              ${trustedNodeUrl} \
              ${backfilling}'';

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
                    ${cfg.package}/bin/nimbus_beacon_node trustedNodeSync "$@"
                  fi
                '';
              in "${script} ${dataDirPath} ${dataDir} ${nodeSyncArgs}"
              else null;
          in
            nameValuePair serviceName (mkIf cfg.enable {
              after = ["network.target"];
              wantedBy = ["multi-user.target"];
              description = "Nimbus Beacon Node (${beaconName})";

              # create service config by merging with the base config
              serviceConfig = mkMerge [
                baseServiceConfig
                {
                  User = serviceName;
                  StateDirectory = serviceName;
                  ExecStartPre = trustedNodeSync;
                  ExecStart = ''${cfg.package}/bin/nimbus_beacon_node ${beaconNodeArgs}'';
                  MemoryDenyWriteExecute = "false"; # causes a library loading error
                }
                (mkIf (cfg.args.jwt-secret != null) {
                  LoadCredential = ["jwt-secret:${cfg.args.jwt-secret}"];
                })
              ];
            })
      )
      eachBeacon;
  };
}
