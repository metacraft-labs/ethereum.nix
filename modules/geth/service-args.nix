{lib, ...}: let
  modulesLib = import ../lib.nix lib;

  inherit (lib.lists) findFirst;
  inherit (lib.strings) hasPrefix;
  inherit (lib) concatStringsSep;
  inherit (modulesLib) mkArgs;
in {
  argsCreate = serviceName: cfg: let
    network =
      if cfg.args.network != null
      then "--${cfg.args.network}"
      else "";

    jwtSecret =
      if cfg.args.authrpc.jwtsecret != null
      then "--authrpc.jwtsecret %d/jwtsecret"
      else "";

    ipc =
      if cfg.args.ipcEnable
      then ""
      else "--ipcdisable";

    datadir =
      if cfg.args.datadir != null
      then "--datadir ${cfg.args.datadir}"
      else "--datadir %S/${serviceName}";
  in rec {
    scriptArgs = let
      # replace enable flags like --http.enable with just --http
      pathReducer = path: let
        arg = concatStringsSep "." (lib.lists.remove "enable" path);
      in "--${arg}";

      # generate flags
      args = let
        opts = import ./args.nix lib;
      in
        mkArgs {
          inherit pathReducer opts;
          inherit (cfg) args;
        };

      # filter out certain args which need to be treated differently
      specialArgs = ["--network" "--authrpc.jwtsecret" "--ipcEnable"];
      isNormalArg = name: (findFirst (arg: hasPrefix arg name) null specialArgs) == null;

      filteredArgs = builtins.filter isNormalArg args;
    in ''
      ${ipc} ${network} \
      ${concatStringsSep " \\\n" filteredArgs} \
      ${lib.escapeShellArgs cfg.extraArgs}
    '';

    systemdPathsArgs = ''
      ${datadir} \
      ${jwtSecret} \
    '';

    execStartCommand =
      if cfg.argsFromFile.enable
      then ''${cfg.package}/bin/geth ${systemdPathsArgs} $ARGS''
      else ''${cfg.package}/bin/geth ${systemdPathsArgs} ${scriptArgs}'';
  };
}
