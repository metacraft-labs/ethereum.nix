{lib, ...}: let
  modulesLib = import ../lib.nix lib;
  inherit (builtins) isBool isList toString;
  inherit (lib) boolToString concatStringsSep findFirst hasPrefix;
  inherit (modulesLib) mkArgs;
in {
  argsCreate = serviceName: cfg: let
    jwtSecret =
      if cfg.args.modules.JsonRpc.JwtSecretFile != null
      then "--JsonRpc.JwtSecretFile %d/jwtsecret"
      else "";
    datadir =
      if cfg.args.datadir != null
      then "--datadir ${cfg.args.datadir}"
      else "--datadir %S/${serviceName}";
  in rec {
    scriptArgs = let
      # custom arg reducer for nethermind
      argReducer = value:
        if (isList value)
        then concatStringsSep "," value
        else if (isBool value)
        then boolToString value
        else toString value;

      # remove modules from arguments
      pathReducer = path: let
        arg = concatStringsSep "." (lib.lists.remove "modules" path);
      in "--${arg}";

      # custom arg formatter for nethermind
      argFormatter = {
        path,
        value,
        argReducer,
        pathReducer,
        ...
      }: let
        arg = pathReducer path;
      in "${arg} ${argReducer value}";

      # generate flags
      args = let
        opts = import ./args.nix lib;
      in
        mkArgs {
          inherit pathReducer argReducer argFormatter opts;
          inherit (cfg) args;
        };

      # filter out certain args which need to be treated differently
      specialArgs = ["--JsonRpc.JwtSecretFile"];
      isNormalArg = name: (findFirst (arg: hasPrefix arg name) null specialArgs) == null;

      filteredArgs = builtins.filter isNormalArg args;
    in ''
      ${concatStringsSep " \\\n" filteredArgs} \
      ${lib.escapeShellArgs cfg.extraArgs}
    '';

    systemdPathsArgs = ''
      ${datadir} \
      ${jwtSecret} \
    '';

    execStartCommand =
      if cfg.argsFromFile.enable
      then ''${cfg.package}/bin/nethermind ${systemdPathsArgs} $ARGS''
      else ''${cfg.package}/bin/nethermind ${systemdPathsArgs} ${scriptArgs}'';
  };
}
