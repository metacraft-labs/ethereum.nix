lib:
with lib; {
  executionClientMode = mkOption {
    type = types.enum ["local" "external"];
    default = "local";
    example = "external";
    description = mdDoc ''
      Choose which mode to use for your Execution client -
      locally managed (Docker Mode), or externally managed (Hybrid Mode).
    '';
  };

  executionClient = mkOption {
    type = types.enum ["geth" "nethermind" "besu"];
    default = "geth";
    example = "nethermind";
    description = mdDoc "Select which Execution client you would like to run.";
  };

  useFallbackClients = mkOption {
    type = types.bool;
    default = false;
    description = mdDoc ''
      Enable this if you would like to specify a fallback Execution and Consensus Client,
      which will temporarily be used by the Smartnode and your Validator Client if
      your primary Execution / Consensus client pair ever go offline
      (e.g. if you switch, prune, or resync your clients).
    '';
  };

  reconnectDelay = mkOption {
    type = types.nullOr types.str;
    default = null;
    example = "60s";
    description = mdDoc ''
      The delay to wait after your primary
      Execution or Consensus clients fail before trying to reconnect to them.
      An example format is "10h20m30s" - this would make it 10 hours, 20 minutes, and 30 seconds.
    '';
  };

  consensusClientMode = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''
      Choose which mode to use for your Consensus client -
      locally managed (Docker Mode), or externally managed (Hybrid Mode).
    '';
  };

  consensusClient = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''Select which Consensus client you would like to use.'';
  };

  externalConsensusClient = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''Select which Consensus client your externally managed client is.'';
  };

  # Metrics

  enableMetrics = lib.mkEnableOption (mdDoc ''
    the Smartnode's performance and status metrics system.
    This will provide you with the node operator's Grafana dashboard.
  '');

  # Smartnode

  smartnode-network = mkOption {
    type = types.nullOr (types.enum ["mainnet" "prater" "holesky"]);
    default = null;
    description = mdDoc ''      
      The Ethereum network you want to use - select Prater Testnet or Holesky Testnet 
      to practice with fake ETH, or Mainnet to stake on the real network using real ETH.'';
  };

  smartnode-projectName = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''      
      This is the prefix that will be attached to all of the 
      Docker containers managed by the Smartnode.'';
  };

  smartnode-dataPath = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''      
      The absolute path of the data folder that contains 
      your node wallet's encrypted file, the password for your node wallet, and 
      all of the validator keys for your minipools. You may use environment variables 
      in this string.'';
  };

  smartnode-manualMaxFee = mkOption {
    type = types.nullOr types.float;
    default = null;
    description = mdDoc ''
      Set this if you want all of the Smartnode's transactions 
      to use this specific max fee value (in gwei), which is the most you'd be willing 
      to pay (*including the priority fee*).'';
  };

  smartnode-priorityFee = mkOption {
    type = types.nullOr types.float;
    default = null;
    description = mdDoc ''
      The default value for the priority fee (in gwei) for all 
      of your transactions. This describes how much you're willing to pay *above the network's 
      current base fee* - the higher this is, the more ETH you give to the validators for 
      including your transaction, which generally means it will be included in a block faster 
      (as long as your max fee is sufficiently high to cover the current network conditions).'';
  };

  smartnode-minipoolStakeGasThreshold = mkOption {
    type = types.nullOr types.float;
    default = null;
    description = mdDoc ''
      Occasionally, the Smartnode will attempt to perform some automatic transactions
      (such as the second stake transaction to finish launching a minipool or the 
      `reduce bond` transaction to convert a 16-ETH minipool to an 8-ETH one). During these, 
      your node will use the `Rapid` suggestion from the gas estimator as its max fee.'';
  };

  smartnode-distributeThreshold = mkOption {
    type = types.nullOr types.float;
    default = null;
    description = mdDoc ''The Smartnode will regularly check the balance of each of your minipools on the Execution Layer (**not** the Beacon Chain).'';
  };

  smartnode-rewardsTreeMode = mkOption {
    type = types.nullOr (types.enum ["download" "generate"]);
    default = null;
    description = mdDoc ''Select how you want to acquire the Merkle Tree files for each rewards interval.'';
  };

  smartnode-rewardsTreeCustomUrl = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''
      The Smartnode will automatically download missing rewards
      tree files from trusted sources like IPFS and Rocket Pool's repository on GitHub. 
      Use this field if you would like to manually specify additional sources that host the 
      rewards tree files, so the Smartnode can download from them as well.'';
  };

  smartnode-archiveECUrl = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''
      **For manual Merkle rewards tree generation only.**[white]
      Generating the Merkle rewards tree files for past rewards intervals typically 
      requires an Execution client with Archive mode enabled, which is usually disabled 
      on your primary and fallback Execution clients to save disk space.
      If you want to generate your own rewards tree files for intervals from a long 
      time ago, you may enter the URL of an Execution client with Archive access here.
      For a free light client with Archive access, you may use https://www.alchemy.com/supernode.'';
  };

  smartnode-watchtowerMaxFeeOverride = mkOption {
    type = types.nullOr types.float;
    default = null;
    description = mdDoc ''
      **For Oracle DAO members only.**
      Use this to override the max fee (in gwei) for watchtower transactions. 
      Note that if you set it below 200, the setting will be ignored; it can only 
      be used to set the max fee higher than 200 during times of extreme network stress.
      For Oracle DAO members only.'';
  };

  smartnode-watchtowerPrioFeeOverride = mkOption {
    type = types.nullOr types.float;
    default = null;
    description = mdDoc ''
      **For Oracle DAO members only.**
      Use this to override the priority fee (in gwei) for watchtower transactions. 
      Note that if you set it below 3, the setting will be ignored; it can only be
      used to set the priority fee higher than 3 during times of extreme network stress.'';
  };

  smartnode-useRollingRecords = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = mdDoc ''
      **WARNING: EXPERIMENTAL**

      Enable this to use the new rolling records feature, which stores attestation
      records for the entire Rocket Pool network in real time instead of collecting
      them all after a rewards period during tree generation.
      Only useful for the Oracle DAO, or if you generate your own rewards trees.
    '';
  };

  smartnode-recordCheckpointInterval = mkOption {
    type = types.nullOr types.ints.unsigned;
    default = null;
    description = mdDoc ''The number of epochs that should pass before saving a new rolling record checkpoint. Used if Rolling Records is enabled.'';
  };

  smartnode-checkpointRetentionLimit = mkOption {
    type = types.nullOr types.ints.unsigned;
    default = null;
    description = mdDoc ''The number of checkpoint files to save on-disk before pruning old ones. Used if Rolling Records is enabled.'';
  };

  smartnode-recordsPath = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''The path of the folder to store rolling record checkpoints in during a rewards interval. Used if Rolling Records is enabled.'';
  };

  # Geth

  geth-enablePbss = lib.mkEnableOption (mdDoc ''
    rocketpool service resync-eth1  Enable Geth's new path-based state scheme. 
    With this enabled, you will no longer need to manually prune Geth; it will automatically prune its database in real-time.

    NOTE:
    Enabling this will require you to remove and resync your Geth DB using rocketpool service resync-eth1.
    You will need a synced fallback node configured before doing this, or you will no longer be able to attest until it has finished resyncing!'');

  geth-maxPeers = mkOption {
    type = types.nullOr types.ints.u16;
    default = null;
    description = mdDoc ''
      The maximum number of peers Geth should connect to. This can be lowered to improve
      performance on low-power systems or constrained config.Networks. We recommend keeping it at 12 or higher.'';
  };

  geth-containerTag = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''The tag name of the Geth container you want to use on Docker Hub.'';
  };

  geth-additionalFlags = mkOption {
    type = types.nullOr (types.listOf types.str);
    default = null;
    description = mdDoc ''
      Additional custom command line flags you want to pass to Geth, to take advantage
      of other settings that the Smartnode's configuration doesn't cover.'';
  };

  # Nethermind

  nethermind-cache = mkOption {
    type = types.nullOr types.ints.unsigned;
    default = null;
    description = mdDoc ''
      The amount of RAM (in MB) you want to suggest for Nethermind's cache. 
      While there is no guarantee that Nethermind will stay under this limit, 
      lower values are preferred for machines with less RAM.'';
  };

  nethermind-maxPeers = mkOption {
    type = types.nullOr types.ints.u16;
    default = null;
    description = mdDoc ''
      The maximum number of peers Nethermind should connect to. This can be lowered
       to improve performance on low-power systems or constrained config.Networks. We recommend keeping it at 12 or higher.'';
  };

  nethermind-pruneMemSize = mkOption {
    type = types.nullOr types.ints.unsigned;
    default = null;
    description = mdDoc ''
      The amount of RAM (in MB) you want to dedicate to Nethermind for its in-memory
       pruning system. Higher values mean less writes to your SSD and slower overall database growth.'';
  };

  nethermind-fullPruneMemoryBudget = mkOption {
    type = types.nullOr types.ints.unsigned;
    default = null;
    description = mdDoc ''
      The amount of RAM (in MB) you want to dedicate to Nethermind for its full 
      pruning system. Higher values mean less writes to your SSD and faster pruning times.'';
  };

  nethermind-additionalModules = mkOption {
    type = types.nullOr (types.listOf types.str);
    default = null;
    description = mdDoc ''
      Additional modules you want to add to the primary JSON-RPC route. 
      The defaults are Eth,Net,Personal,Web3. You can add any additional ones you 
      need here'';
  };

  nethermind-additionalUrls = mkOption {
    type = types.nullOr (types.listOf types.str);
    default = null;
    description = mdDoc ''
      Additional JSON-RPC URLs you want to run alongside the primary URL.
      These will be added to the "--JsonRpc.AdditionalRpcUrls" argument.
      Please consult the Nethermind documentation for more information on this flag, its intended usage, and its expected formatting.
    '';
  };

  nethermind-containerTag = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''The tag name of the Nethermind container you want to use on Docker Hub.'';
  };

  nethermind-additionalFlags = mkOption {
    type = types.nullOr (types.listOf types.str);
    default = null;
    description = mdDoc ''
      Additional custom command line flags you want to pass to Nethermind, 
      to take advantage of other settings that the Smartnode's configuration doesn't cover.'';
  };

  # Nimbus

  externalNimbus-httpUrl = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''The URL of the HTTP Beacon API endpoint for your external client.'';
  };

  externalNimbus-graffiti = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''Add a short message to any blocks you propose, so the world can see what you have to say!'';
  };

  externalNimbus-doppelgangerDetection = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = mdDoc ''
      enabled, your client will *intentionally* miss 1 or 2 
      attestations on startup to check if validator keys are already running elsewhere. 
      If they are, it will disable validation duties for them to prevent you from being slashed.'';
  };

  externalNimbus-containerTag = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''
      The tag name of the Nimbus validator container you want
      to use from Docker Hub. This will be used for the Validator Client that Rocket Pool manages with your minipool keys.'';
  };

  externalNimbus-additionalVcFlags = mkOption {
    type = types.nullOr (types.listOf types.str);
    default = null;
    description = mdDoc ''
      Additional custom command line flags you want to pass Nimbus's Validator Client,
      to take advantage of other settings that the Smartnode's configuration doesn't cover.'';
  };

  nimbus-maxPeers = mkOption {
    type = types.nullOr types.ints.u16;
    default = null;
    description = mdDoc ''
      The maximum number of peers your client should try to 
      maintain. You can try lowering this if you have a low-resource system or a constrained network.'';
  };

  nimbus-pruningMode = mkOption {
    type = types.nullOr (types.enum ["archive" "prune"]);
    default = null;
    description = mdDoc ''Choose how Nimbus will prune its database. Highlight each option to learn more about it.'';
  };

  nimbus-bnContainerTag = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''The tag name of the Nimbus Beacon Node container you want to use on Docker Hub.'';
  };

  nimbus-containerTag = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''The tag name of the Nimbus Validator Client container you want to use on Docker Hub.'';
  };

  nimbus-additionalBnFlags = mkOption {
    type = types.nullOr (types.listOf types.str);
    default = null;
    description = mdDoc ''
      Additional custom command line flags you want to pass
      Nimbus's Beacon Client, to take advantage of other settings that the Smartnode's configuration doesn't cover.'';
  };

  nimbus-additionalVcFlags = mkOption {
    type = types.nullOr (types.listOf types.str);
    default = null;
    description = mdDoc ''
      Additional custom command line flags you want to pass Nimbus's Validator Client,
      to take advantage of other settings that the Smartnode's configuration doesn't cover.'';
  };

  # MEV-Boost

  enableMevBoost = lib.mkEnableOption (mdDoc ''
    MEV-Boost, which connects your validator to one or more relays of your choice.
    The relays act as intermediaries between you and professional block builders
    that find and extract MEV opportunities. The builders will give you a healthy
    tip in return, which tends to be worth more than blocks you built on your own.
  '');

  mevBoost-mode = mkOption {
    type = types.nullOr (types.enum ["local" "external"]);
    default = null;
    description = mdDoc ''
      Choose whether to let the Smartnode manage your MEV-Boost instance
      (Locally Managed), or if you manage your own outside of the Smartnode 
      stack (Externally Managed).'';
  };

  mevBoost-selectionMode = mkOption {
    type = types.nullOr (types.enum ["profile" "relay"]);
    default = null;
    description = mdDoc ''Select how the TUI shows you the options for which MEV relays to enable.'';
  };

  mevBoost-enableRegulatedAllMev = lib.mkEnableOption (mdDoc ''
    To learn more about MEV, please visit https://docs.rocketpool.net/guides/node/mev.html.
    Select this to enable the relays that comply with government regulations (e.g. OFAC sanctions), 
    Relays: Flashbots, bloXroute Regulated, Eden Network'');

  mevBoost-enableUnregulatedAllMev = lib.mkEnableOption (mdDoc ''
    To learn more about MEV, please visit https://docs.rocketpool.net/guides/node/mev.html.
    Select this to enable the relays that do not follow any sanctions lists (do not censor transactions),
    Relays: bloXroute Max Profit, Ultra Sound, Aestus
  '');

  mevBoost-flashbotsEnabled = lib.mkEnableOption (mdDoc ''
    To learn more about MEV, please visit https://docs.rocketpool.net/guides/node/mev.html.
    Flashbots is the developer of MEV-Boost, and one of the best-known and most trusted relays in the space.
    Complies with Regulations: YES'');

  mevBoost-bloxRouteMaxProfitEnabled = lib.mkEnableOption (mdDoc ''
    To learn more about MEV, please visit https://docs.rocketpool.net/guides/node/mev.html.
    Select this to enable the "max profit" relay from bloXroute.
    Complies with Regulations: NO
  '');

  mevBoost-bloxRouteRegulatedEnabled = lib.mkEnableOption (mdDoc ''
    To learn more about MEV, please visit https://docs.rocketpool.net/guides/node/mev.html.
    Select this to enable the "regulated" relay from bloXroute.
    Complies with Regulations: YES'');

  mevBoost-edenEnabled = lib.mkEnableOption (mdDoc ''    
    To learn more about MEV, please visit https://docs.rocketpool.net/guides/node/mev.html.
    Eden Network is the home of Eden Relay, a block building hub focused on optimising block rewards for validators.
    Complies with Regulations: YES'');

  mevBoost-ultrasoundEnabled = lib.mkEnableOption (mdDoc ''
    To learn more about MEV, please visit https://docs.rocketpool.net/guides/node/mev.html.
    The ultra sound relay is a credibly-neutral and permissionless relay — a public good from the ultrasound.money team.
    Complies with Regulations: NO'');

  mevBoost-aestusEnabled = lib.mkEnableOption (mdDoc ''
    To learn more about MEV, please visit https://docs.rocketpool.net/guides/node/mev.html.
    The Aestus MEV-Boost Relay is an independent and non-censoring relay. 
    It is committed to neutrality and the development of a healthy MEV-Boost ecosystem.
    Complies with Regulations: NO'');

  mevBoost-port = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''The port that MEV-Boost should serve its API on.'';
  };

  mevBoost-openRpcPort = mkOption {
    type = types.nullOr (types.enum ["closed" "localhost" "external"]);
    default = null;
    description = mdDoc ''
      Expose the API port to other processes on your machine,
      or to your local network so other local machines can access MEV-Boost's API.
    '';
  };

  mevBoost-containerTag = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''The tag name of the MEV-Boost container you want to use on Docker Hub.'';
  };

  mevBoost-additionalFlags = mkOption {
    type = types.nullOr (types.listOf types.str);
    default = null;
    description = mdDoc ''
      Additional custom command line flags you want to pass
      to MEV-Boost, to take advantage of other settings that the Smartnode's 
      configuration doesn't cover.'';
  };

  mevBoost-externalUrl = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = mdDoc ''The URL of the external MEV-Boost client or provider'';
  };
}
