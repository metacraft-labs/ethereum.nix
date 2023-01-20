{
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) isString toString isList;
  inherit (lib) types;
  inherit (lib.lists) flatten;
  inherit (lib.options) isOption;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.asserts) assertMsg;
  inherit (lib.attrsets) attrByPath foldAttrs hasAttrByPath getAttrByPath filterAttrsRecursive;
  inherit (lib.attrsets) mapAttrsRecursive mapAttrsRecursiveCond collect;

  tomlGenerator = pkgs.formats.toml {};

  defaultArgReducer = value:
    if (isList value)
    then concatStringsSep "," value
    else toString value;

  defaultPathReducer = path: let
    arg = concatStringsSep "-" path;
  in "--${arg}";

  dotPathReducer = path: let
    arg = concatStringsSep "." path;
  in "--${arg}";

  mkFlag = {
    path,
    opt,
    args,
    argReducer ? defaultArgReducer,
    pathReducer ? defaultPathReducer,
  }: let
    value = attrByPath path opt.default args;
    hasValue = (hasAttrByPath path args) && value != null;
    hasDefault = (hasAttrByPath ["default"] opt) && value != null;
  in
    assert assertMsg (isOption opt) "opt must be an option";
      if (hasValue || hasDefault)
      then let
        arg = pathReducer path;
      in
        if (opt.type == types.bool && value)
        then "${arg}"
        else "${arg} ${argReducer value}"
      else "";

  mkFlags = {
    opts,
    args,
    pathReducer ? defaultPathReducer,
  }:
    collect (v: (isString v) && v != "") (
      mapAttrsRecursiveCond
      (as: !isOption as)
      (path: opt: mkFlag {inherit path opt args pathReducer;})
      opts
    );
in {
  flags = {
    inherit mkFlag mkFlags defaultPathReducer dotPathReducer;
  };
}