/*
* Derived from https://github.com/NixOS/nixpkgs/blob/45b92369d6fafcf9e462789e98fbc735f23b5f64/nixos/modules/services/blockchain/ethereum/geth.nix
*/
{
  config,
  lib,
  pkgs,
  ...
}: let
  modulesLib = import ../lib.nix lib;

  serviceArgs =
    lib.mapAttrs (
      gethName: let
        serviceName = "geth-${gethName}";
      in
        cfg: ((import ./service-args.nix {inherit lib pkgs;}).argsCreate serviceName cfg)
    )
    eachGeth;

  inherit (lib.lists) optionals;
  inherit (lib.attrsets) zipAttrsWith;
  inherit (lib) filterAttrs flatten mapAttrs' mapAttrsToList mkIf mkMerge nameValuePair;
  inherit (modulesLib) baseServiceConfig;

  # capture config for all configured geths
  eachGeth = config.services.ethereum.geth;
in {
  # Disable the service definition currently in nixpkgs
  disabledModules = ["services/blockchain/ethereum/geth.nix"];

  ###### interface
  inherit (import ./options.nix {inherit lib pkgs;}) options;

  ###### implementation

  config = mkIf (eachGeth != {}) {
    # configure the firewall for each service
    networking.firewall = let
      openFirewall = filterAttrs (_: cfg: cfg.openFirewall) eachGeth;
      perService =
        mapAttrsToList
        (
          _: cfg:
            with cfg.args; {
              allowedUDPPorts = [port];
              allowedTCPPorts =
                [port authrpc.port]
                ++ (optionals http.enable [http.port])
                ++ (optionals ws.enable [ws.port])
                ++ (optionals metrics.enable [metrics.port]);
            }
        )
        openFirewall;
    in
      zipAttrsWith (_name: flatten) perService;

    environment = lib.mapAttrs' (gethName: cfg:
      lib.nameValuePair "etc" {
        "ethereum/geth-${gethName}-args" = let
          inherit (cfg) argsFromFile;
        in
          lib.mkIf argsFromFile.enable {
            source = builtins.toFile "geth-${gethName}-args" ''
              ARGS="${serviceArgs.${gethName}.scriptArgs}"
            '';
            inherit (argsFromFile) group;
            inherit (argsFromFile) mode;
          };
      })
    eachGeth;

    # create a service for each instance
    systemd.services =
      mapAttrs'
      (
        gethName: let
          serviceName = "geth-${gethName}";
        in
          cfg: let
            inherit (serviceArgs."${gethName}") execStartCommand;
          in
            nameValuePair serviceName (mkIf cfg.enable {
              after = ["network.target"];
              wantedBy = ["multi-user.target"];
              description = "Go Ethereum node (${gethName})";

              environment = {
                WEB3_HTTP_HOST = cfg.args.http.addr;
                WEB3_HTTP_PORT = builtins.toString cfg.args.http.port;
              };

              # create service config by merging with the base config
              serviceConfig = mkMerge [
                baseServiceConfig
                {
                  User = serviceName;
                  EnvironmentFile = lib.mkIf cfg.argsFromFile.enable "/etc/ethereum/geth-${gethName}-args";
                  StateDirectory = serviceName;
                  ExecStart = execStartCommand;
                }
                (mkIf (cfg.args.authrpc.jwtsecret != null) {
                  LoadCredential = ["jwtsecret:${cfg.args.authrpc.jwtsecret}"];
                })
              ];
            })
      )
      eachGeth;
  };
}
