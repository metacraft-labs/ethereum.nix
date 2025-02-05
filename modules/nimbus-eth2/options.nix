{
  lib,
  pkgs,
  ...
}: let
  args = import ./args.nix lib;
  nimbusOpts = with lib; {
    options = {
      enable = mkEnableOption "Nimbus Beacon Node service";

      inherit args;

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [
          "--num-threads=1"
          "--graffiti=1337_h4x0r"
        ];
        description = "Additional arguments passed to node.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.nimbus;
        defaultText = literalExpression "pkgs.nimbus";
        description = "Package to use for Nimbus Beacon Node binary";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = "Open ports in the firewall for any enabled networking services";
      };

      argsFromFile = {
        enable = mkEnableOption "Create a file in the etc directory from which arguments can be modified";
        group = mkOption {
          type = types.str;
          default = "";
          example = "devops";
          description = "Group which can modify the arguments file";
        };
        mode = mkOption {
          type = types.str;
          default = "0664";
          example = "0060";
          description = "Arguments file mode";
        };
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
  options.services.ethereum.nimbus-eth2 = with lib;
    mkOption {
      type = types.attrsOf (types.submodule nimbusOpts);
      default = {};
      description = "Specification of one or more Nimbus Beacon Node instances.";
    };
}
