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

  eachRocketPool = config.services.ethereum.rocketpool;
in {
  ###### interface
  inherit (import ./options.nix {inherit lib pkgs;}) options;

  ###### implementation

  config = mkIf (eachRocketPool != {}) {
    systemd.services =
      mapAttrs'
      (
        rocketpool: let
          serviceName = "rocketpool";
        in
          cfg: let
            geth-additionalFlags =
              if cfg.args.geth-additionalFlags != null
              then ''--geth-additionalFlags=${concatStringsSep "," cfg.args.geth-additionalFlags}''
              else "";

            nethermind-additionalModules =
              if cfg.args.nethermind-additionalModules != null
              then ''--nethermind-additionalModules=${concatStringsSep "," cfg.args.nethermind-additionalModules}''
              else "";

            nethermind-additionalUrls =
              if cfg.args.nethermind-additionalUrls != null
              then ''--nethermind-additionalUrls=${concatStringsSep "," cfg.args.nethermind-additionalUrls}''
              else "";

            nethermind-additionalFlags =
              if cfg.args.nethermind-additionalFlags != null
              then ''--nethermind-additionalFlags=${concatStringsSep "," cfg.args.nethermind-additionalFlags}''
              else "";

            externalNimbus-additionalVcFlags =
              if cfg.args.externalNimbus-additionalVcFlags != null
              then ''--externalNimbus-additionalVcFlags=${concatStringsSep "," cfg.args.externalNimbus-additionalVcFlags}''
              else "";

            nimbus-additionalBnFlags =
              if cfg.args.nimbus-additionalBnFlags != null
              then ''--nimbus-additionalBnFlags=${concatStringsSep "," cfg.args.nimbus-additionalBnFlags}''
              else "";

            nimbus-additionalVcFlags =
              if cfg.args.nimbus-additionalVcFlags != null
              then ''--nimbus-additionalVcFlags=${concatStringsSep "," cfg.args.nimbus-additionalVcFlags}''
              else "";

            mevBoost-additionalFlags =
              if cfg.args.mevBoost-additionalFlags != null
              then ''--mevBoost-additionalFlags=${concatStringsSep "," cfg.args.mevBoost-additionalFlags}''
              else "";

            serviceArgs = let
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
              specialArgs = [
                "--geth-additionalFlags"
                "--nethermind-additionalModules"
                "--nethermind-additionalUrls"
                "--nethermind-additionalFlags"
                "--externalNimbus-additionalVcFlags"
                "--nimbus-additionalBnFlags"
                "--nimbus-additionalVcFlags"
                "--mevBoost-additionalFlags"
              ];
              isNormalArg = name: (findFirst (arg: hasPrefix arg name) null specialArgs) == null;
              filteredArgs = builtins.filter isNormalArg args;
            in
              builtins.concatStringsSep " \\\n" (
                builtins.filter (x: x != null && x != "") [
                  geth-additionalFlags
                  nethermind-additionalModules
                  nethermind-additionalUrls
                  nethermind-additionalFlags
                  externalNimbus-additionalVcFlags
                  nimbus-additionalBnFlags
                  nimbus-additionalVcFlags
                  mevBoost-additionalFlags
                  (concatStringsSep " \\\n" filteredArgs)
                  (lib.escapeShellArgs cfg.extraArgs)
                ]
              );
          in
            nameValuePair serviceName (mkIf cfg.enable {
              after = ["network.target"];
              wantedBy = ["multi-user.target"];
              description = "Rocket Pool service (${rocketpool})";

              # create service config by merging with the base config
              serviceConfig = mkMerge [
                baseServiceConfig
                {
                  User = serviceName;
                  StateDirectory = serviceName;
                  ExecStart = ''${lib.getExe cfg.package} service config ${serviceArgs}'';
                  MemoryDenyWriteExecute = "false"; # causes a library loading error
                }
                # (mkIf (cfg.args.jwt-secret != null) {
                #   LoadCredential = ["jwt-secret:${cfg.args.jwt-secret}"];
                # })
              ];
            })
      )
      eachRocketPool;
  };
}
