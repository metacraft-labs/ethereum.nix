{
  blst,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mev-boost-relay";
  version = "0.27.0";

  src = fetchFromGitHub {
    owner = "flashbots";
    repo = "${pname}";
    rev = "v${version}";
    hash = "sha256-SZ1XMuggGmEe7PQ5K/t6nRSEbi3++kNmlgLHF1+dUqA=";
  };

  vendorHash = "sha256-OpxWv5+srcSD/b6SaqQqkdZoRCyIEPIpNH6GUkT2M/Y=";

  buildInputs = [blst];

  subPackages = ["."];

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${version}"
  ];

  meta = {
    description = "MEV-Boost Relay for Ethereum proposer/builder separation (PBS)";
    homepage = "https://github.com/flashbots/mev-boost-relay";
    mainProgram = "mev-boost-relay";
    platforms = ["x86_64-linux"];
  };
}
