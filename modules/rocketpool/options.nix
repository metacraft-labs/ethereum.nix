{
  lib,
  pkgs,
  ...
}: let
  args = import ./args.nix lib;
  rocketpoolOpts = with lib; {
    options = {
      enable = mkEnableOption (mdDoc "Rocket Pool service");

      inherit args;

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        description = mdDoc "Additional arguments passed to service.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.rocketpool;
        defaultText = literalExpression "pkgs.rocketpool";
        description = mdDoc "Package to use for Rocket Pool";
      };

      # mixin backup options
      backup = let
        inherit (import ../backup/lib.nix lib) options;
      in
        options;

      # mixin restore options
      restore = let
        inherit (import ../restore/lib.nix lib) options;
      in
        options;
    };
  };
in {
  options.services.ethereum.rocketpool = with lib;
    mkOption {
      type = types.attrsOf (types.submodule rocketpoolOpts);
      default = {};
      description = mdDoc "Specification of one or more Rocket Pool instances.";
    };
}
