{
  self,
  inputs,
  lib,
  ...
}: {
  # add all our packages based on host platform
  flake.overlays.default = _final: prev: let
    inherit (prev.stdenv.hostPlatform) system;
  in
    self.packages.${system};

  perSystem = {
    self',
    pkgs,
    pkgsUnstable,
    system,
    ...
  }: let
    inherit (pkgs) callPackage;
    inherit (lib.extras.flakes) platformPkgs platformApps;
    poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix {inherit pkgs;};
    callPackageUnstable = pkgsUnstable.callPackage;
  in {
    packages = platformPkgs system rec {
      # Consensus Clients
      lighthouse = callPackage ./clients/consensus/lighthouse {inherit foundry;};
      prysm = callPackage ./clients/consensus/prysm {inherit bls blst;};
      teku = callPackage ./clients/consensus/teku {};
      nimbus = callPackageUnstable ./clients/consensus/nimbus {};
      nimbus-eth2 = callPackageUnstable ./clients/consensus/nimbus-eth2 {
        # For now the nimbus team prefers nim 1.6 over 2.0.
        # In newer versions of `pkgsUnstable` `nim` points to v2.0.0 in older it is 1.6.
        # In newer versions the `nim1` package exists but not in older.
        # See: https://github.com/status-im/nimbus-build-system/commits/master/vendor
        nim = pkgsUnstable.nim1 or pkgsUnstable.nim;
      };

      # Execution Clients
      erigon = callPackage ./clients/execution/erigon {};
      erigon-blst-portable = erigon.overrideAttrs (_finalAttrs: _previousAttrs: {
        CGO_CFLAGS = "-O -D__BLST_PORTABLE__";
      });
      besu = callPackage ./clients/execution/besu {};
      geth = callPackage ./clients/execution/geth {};
      geth-sealer = callPackage ./clients/execution/geth-sealer {};
      nethermind = callPackageUnstable ./clients/execution/nethermind {};
      reth = callPackageUnstable ./clients/execution/reth {};

      # Signers
      web3signer = callPackage ./signers/web3signer {};
      dirk = callPackage ./signers/dirk {inherit bls mcl;};

      # Validators
      vouch = callPackage ./validators/vouch {inherit bls mcl;};

      # MEV
      dreamboat = callPackage ./mev/dreamboat {inherit blst;};
      mev-boost = callPackage ./mev/mev-boost {inherit blst;};
      mev-boost-builder = callPackage ./mev/mev-boost-builder {inherit blst;};
      mev-boost-prysm = callPackage ./mev/mev-boost-prysm {inherit bls blst;};
      mev-boost-relay = callPackage ./mev/mev-boost-relay {inherit blst;};

      mev-rs = callPackage ./mev/mev-rs {};

      # DVT
      charon = callPackage ./dvt/charon {inherit bls mcl;};
      ssvnode = callPackage ./dvt/ssvnode {inherit bls mcl;};

      # Utils
      eigenlayer = callPackage ./utils/eigenlayer {};
      eth2-testnet-genesis = callPackage ./utils/eth2-testnet-genesis {inherit bls;};
      eth2-val-tools = callPackage ./utils/eth2-val-tools {inherit bls mcl;};
      ethdo = callPackage ./utils/ethdo {inherit bls mcl;};
      ethereal = callPackage ./utils/ethereal {inherit bls mcl;};
      heimdall = callPackage ./utils/heimdall {};
      rocketpool = callPackage ./utils/rocketpool {};
      sedge = callPackage ./utils/sedge {inherit bls mcl;};
      staking-deposit-cli = callPackage ./utils/staking-deposit-cli {};
      tx-fuzz = callPackage ./utils/tx-fuzz {};
      zcli = callPackage ./utils/zcli {};

      # Dev
      foundry = inputs.foundry-nix.defaultPackage.${system}.overrideAttrs (_oldAttrs: {
        # TODO: Uncomment when https://github.com/shazow/foundry.nix/issues/23
        # meta.platforms = [system];
        meta.platforms = ["x86_64-linux" "aarch64-linux"];
      });

      # Editors
      vscode-plugin-ackee-blockchain-solidity-tools = callPackage ./editors/vscode/extensions/ackee-blockchain.solidity-tools {};
      vscode-plugin-consensys-vscode-solidity-visual-editor = callPackage ./editors/vscode/extensions/consensys.vscode-solidity-auditor {};

      # Solidity
      slither = callPackage ./solidity/analyzers/slither {};
      wake = callPackage ./solidity/frameworks/wake {
        inherit poetry2nix;
      };

      # Libs
      evmc = callPackage ./libs/evmc {};
      mcl = callPackage ./libs/mcl {};
      bls = callPackage ./libs/bls {};
      blst = callPackage ./libs/blst {};
    };

    apps = platformApps self'.packages {
      # consensus clients / prysm
      prysm = {
        prysm-beacon-chain.bin = "beacon-chain";
        prysm-validator.bin = "validator";
        prysm-client-stats.bin = "client-stats";
        prysm-ctl.bin = "prysmctl";
      };

      # consensus / teku
      teku.bin = "teku";

      # consensus / lighthouse
      lighthouse.bin = "lighthouse";

      # consensus / nimbus
      nimbus = {
        nimbus-beacon-node.bin = "nimbus_beacon_node";
        nimbus-validator-client.bin = "nimbus_validator_client";
      };

      # consensus / nimbus-eth2
      nimbus-eth2.bin = "nimbus_beacon_node";

      # execution clients
      besu.bin = "besu";
      erigon.bin = "erigon";
      reth.bin = "reth";

      geth = {
        bin = "geth";
        geth-abidump.bin = "abidump";
        geth-abigen.bin = "abigen";
        geth-bootnode.bin = "bootnode";
        geth-clef.bin = "clef";
        geth-devp2p.bin = "devp2p";
        geth-ethkey.bin = "ethkey";
        geth-evm.bin = "evm";
        geth-faucet.bin = "faucet";
        geth-rlpdump.bin = "rlpdump";
      };

      geth-sealer.bin = "geth";

      nethermind = {
        nethermind.bin = "Nethermind.Cli";
        nethermind-runner.bin = "Nethermind.Runner";
      };

      # dvt
      charon.bin = "charon";
      ssvnode.bin = "ssvnode";

      # mev
      dreamboat.bin = "dreamboat";
      mev-boost-builder.bin = "geth";
      mev-boost-prysm.bin = "beacon-chain";
      mev-boost-relay.bin = "mev-boost-relay";
      mev-boost.bin = "mev-boost";

      mev-rs.bin = "mev";

      # Signers
      dirk.bin = "dirk";

      # Validators
      vouch.bin = "vouch";

      # Dev
      foundry = {
        anvil.bin = "anvil";
        cast.bin = "cast";
        forge.bin = "forge";
      };

      # Solidity
      slither.bin = "slither";
      wake.bin = "wake";

      # utils
      eth2-testnet-genesis.bin = "eth2-testnet-genesis";
      eth2-val-tools.bin = "eth2-val-tools";
      ethdo.bin = "ethdo";
      ethereal.bin = "ethereal";
      rocketpool.bin = "rocketpool";
      sedge.bin = "sedge";
      staking-deposit-cli.bin = "deposit";
      tx-fuzz.bin = "tx-fuzz";
      zcli.bin = "zcli";
    };
  };
}
