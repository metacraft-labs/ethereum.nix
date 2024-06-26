lib:
with lib; {
  network = mkOption {
    type = types.nullOr (types.enum ["goerli" "prater" "ropsten" "sepolia" "holesky" "gnosis" "chiado"]);
    default = null;
    description = mdDoc "The network to connect to. Mainnet (null) is the default ethereum network.";
  };

  jwt-secret = mkOption {
    type = types.path;
    default = null;
    example = "/var/run/nimbus/jwtsecret";
    description = mdDoc ''
      Path of file with 32 bytes long JWT secret for Auth RPC endpoint.
      Can be generated using 'openssl rand -hex 32'.
    '';
  };

  udp-port = mkOption {
    type = types.either types.port (types.enum ["\${UDP_PORT}"]);
    default = 12000;
    description = mdDoc "The port used by discv5.";
  };

  tcp-port = mkOption {
    type = types.either types.port (types.enum ["\${TCP_PORT}"]);
    default = 13000;
    description = mdDoc "The port used by libp2p.";
  };

  subscribe-all-subnets = mkOption {
    type = types.bool;
    default = false;
    description = mdDoc "Subscribe to all attestation subnet topics.";
  };

  doppelganger-detection = mkOption {
    type = types.bool;
    default = true;
    description = mdDoc ''
      Protection against slashing due to double-voting.
      Means you will miss two attestations when restarting.
    '';
  };

  suggested-fee-recipient = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''
      Wallet address where transaction fee tips - priority fees,
      unburnt portion of gas fees - will be sent.
    '';
  };

  nat = mkOption {
    type = types.str;
    default = "any";
    example = "extip:12.34.56.78";
    description = mdDoc ''
      Method for determining public address. (any, none, upnp, pmp, extip:IP)
    '';
  };

  metrics = {
    enable = lib.mkEnableOption (mdDoc "Nimbus beacon node metrics endpoint");
    address = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = mdDoc "Metrics address for beacon node.";
    };
    port = mkOption {
      type = types.either types.port (types.enum ["\${METRICS_PORT}"]);
      default = 8008;
      description = mdDoc "Metrics port for beacon node.";
    };
  };

  rest = {
    enable = lib.mkEnableOption (mdDoc "Nimbus beacon node REST API");
    address = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = mdDoc "Listening address of the REST API server.";
    };

    port = mkOption {
      type = types.either types.port (types.enum ["\${REST_PORT}"]);
      default = 5052;
      description = mdDoc "Port for the REST API server.";
    };
  };

  log = {
    level = mkOption {
      type = types.enum ["trace" "debug" "info" "notice" "warn" "error" "fatal" "none" "\${LOG_LEVEL}"];
      default = "info";
      example = "debug";
      description = mdDoc "Logging level.";
    };

    format = mkOption {
      type = types.enum ["auto" "colors" "nocolors" "json"];
      default = "auto";
      example = "json";
      description = mdDoc "Logging formatting.";
    };
  };

  web3-signer-url = mkOption {
    type = types.listOf types.str;
    default = [];
    example = ["http://localhost:9000/"];
    description = mdDoc "Remote Web3Signer URL that will be used as a source of validators.";
  };

  web3-urls = mkOption {
    type = types.listOf types.str;
    default = [];
    example = ["http://localhost:8551/"];
    description = mdDoc "Mandatory URL(s) for the Web3 RPC endpoints.";
  };

  trusted-node-url = mkOption {
    type = types.nullOr types.str;
    default = null;
    example = "http://localhost:5052/";
    description = mdDoc "URL for Trusted Node Sync.";
  };

  backfill = mkOption {
    type = types.nullOr types.bool;
    default = true;
    description = mdDoc "History backfill.";
  };

  payload-builder = {
    enable = lib.mkEnableOption (mdDoc "Enable external payload builder.");
    url = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "http://localhost:18550/";
      description = mdDoc "Payload builder URL.";
    };
  };

  keymanager = {
    enable = lib.mkEnableOption (mdDoc "Enable the REST keymanager API");
    address = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = mdDoc "Listening port for the REST keymanager API.";
    };

    port = mkOption {
      type = types.either types.port (types.enum ["\${KEYMANAGER_PORT}"]);
      default = 5052;
      description = mdDoc "Listening port for the REST keymanager API.";
    };

    allow-origin = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = mdDoc "Limit the access to the Keymanager API to a particular hostname (for CORS-enabled clients such as browsers).";
    };

    token-file = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = mdDoc "A file specifying the authorization token required for accessing the keymanager API.";
    };
  };
}
