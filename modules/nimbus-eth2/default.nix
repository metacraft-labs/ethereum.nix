{
  config,
  lib,
  pkgs,
  ...
}: let
  modulesLib = import ../lib.nix lib;

  serviceArgs =
    lib.mapAttrs (
      _beaconName: let
        serviceName = "nimbus-eth2";
      in
        cfg: ((import ./service-args.nix {inherit lib pkgs;}).argsCreate serviceName cfg)
    )
    eachBeacon;

  inherit (lib.attrsets) zipAttrsWith;
  inherit (lib) filterAttrs flatten mapAttrs' mapAttrsToList mkIf mkMerge nameValuePair;
  inherit (modulesLib) baseServiceConfig;

  eachBeacon = config.services.ethereum.nimbus-eth2;
in {
  ###### interface
  inherit (import ./options.nix {inherit lib pkgs;}) options;

  ###### implementation

  config = mkIf (eachBeacon != {}) {
    assertions =
      mapAttrsToList
      (
        _name: cfg: {
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

    environment = lib.mapAttrs' (beaconName: cfg:
      lib.nameValuePair "etc" {
        "ethereum/nimbus-${beaconName}-args" = let
          inherit (cfg) argsFromFile;
        in
          lib.mkIf argsFromFile.enable {
            source = builtins.toFile "nimbus-${beaconName}-args" ''
              ARGS="${serviceArgs.${beaconName}.beaconNodeArgs}"
            '';
            inherit (argsFromFile) group;
            inherit (argsFromFile) mode;
          };
      })
    eachBeacon;

    systemd.services =
      mapAttrs'
      (
        beaconName: let
          serviceName = "nimbus-eth2";
        in
          cfg: let
            inherit (serviceArgs."${beaconName}") trustedNodeSync execStartCommand;
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
                  EnvironmentFile = lib.mkIf cfg.argsFromFile.enable "/etc/ethereum/nimbus-${beaconName}-args";
                  ExecStartPre = trustedNodeSync;
                  ExecStart = execStartCommand;
                  MemoryDenyWriteExecute = "false"; # causes a library loading error
                }
                (mkIf (cfg.args.jwt-secret != null) {
                  LoadCredential = ["jwt-secret:${cfg.args.jwt-secret}"];
                })
                (mkIf (cfg.args.keymanager.token-file != null) {
                  LoadCredential = ["keymanager-token-file:${cfg.args.keymanager.token-file}"];
                })
              ];
            })
      )
      eachBeacon;
  };
}
