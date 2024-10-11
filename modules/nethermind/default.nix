{
  config,
  lib,
  pkgs,
  ...
}: let
  serviceArgs =
    lib.mapAttrs (
      nethermindName: let
        serviceName = "nethermind-${nethermindName}";
      in
        cfg: ((import ./service-args.nix {inherit lib pkgs;}).argsCreate serviceName cfg)
    )
    eachNethermind;

  inherit (builtins) toString;
  inherit (lib) filterAttrs flatten mapAttrs' mapAttrsToList mkIf mkMerge nameValuePair optionals zipAttrsWith;

  modulesLib = import ../lib.nix lib;
  inherit (modulesLib) baseServiceConfig;

  # capture config for all configured netherminds
  eachNethermind = config.services.ethereum.nethermind;
in {
  ###### interface
  inherit (import ./options.nix {inherit lib pkgs;}) options;

  ###### implementation

  config = mkIf (eachNethermind != {}) {
    # configure the firewall for each service
    networking.firewall = let
      openFirewall = filterAttrs (_: cfg: cfg.openFirewall) eachNethermind;
      perService =
        mapAttrsToList
        (
          _: cfg:
            with cfg.args; {
              allowedUDPPorts = [modules.Network.DiscoveryPort];
              allowedTCPPorts =
                [modules.Network.P2PPort modules.JsonRpc.EnginePort]
                ++ (optionals modules.JsonRpc.Enabled [modules.JsonRpc.Port modules.JsonRpc.WebSocketsPort])
                ++ (optionals modules.Metrics.Enabled && (modules.Metrics.ExposePort != null) [modules.Metrics.ExposePort]);
            }
        )
        openFirewall;
    in
      zipAttrsWith (_name: flatten) perService;

    environment = lib.mapAttrs' (nethermindName: cfg:
      lib.nameValuePair "etc" {
        "ethereum/nethermind-${nethermindName}-args" = let
          inherit (cfg) argsFromFile;
        in
          lib.mkIf argsFromFile.enable {
            source = builtins.toFile "nethermind-${nethermindName}-args" ''
              ARGS="${serviceArgs.${nethermindName}.scriptArgs}"
            '';
            inherit (argsFromFile) group;
            inherit (argsFromFile) mode;
          };
      })
    eachNethermind;

    # create a service for each instance
    systemd.services =
      mapAttrs' (
        nethermindName: let
          serviceName = "nethermind-${nethermindName}";
        in
          cfg: let
            inherit (serviceArgs."${nethermindName}") execStartCommand;
          in
            nameValuePair serviceName (mkIf cfg.enable {
              after = ["network.target"];
              wantedBy = ["multi-user.target"];
              description = "Nethermind Node (${nethermindName})";

              environment = {
                WEB3_HTTP_HOST = cfg.args.modules.JsonRpc.EngineHost;
                WEB3_HTTP_PORT = builtins.toString cfg.args.modules.JsonRpc.Port;
              };

              # create service config by merging with the base config
              serviceConfig = mkMerge [
                {
                  User = serviceName;
                  EnvironmentFile = lib.mkIf cfg.argsFromFile.enable "/etc/ethereum/nethermind-${nethermindName}-args";
                  StateDirectory = serviceName;
                  MemoryDenyWriteExecute = false; # setting this option is incompatible with JIT
                  ExecStart = execStartCommand;
                }
                baseServiceConfig
                (mkIf (cfg.args.modules.JsonRpc.JwtSecretFile != null) {
                  LoadCredential = ["jwtsecret:${cfg.args.modules.JsonRpc.JwtSecretFile}"];
                })
              ];
            })
      )
      eachNethermind;
  };
}
