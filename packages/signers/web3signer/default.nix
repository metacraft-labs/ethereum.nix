{
  fetchzip,
  jre,
  lib,
  makeWrapper,
  stdenv,
}:
stdenv.mkDerivation rec {
  pname = "web3signer";
  version = "24.1.0";

  src = fetchzip {
    url = "https://artifacts.consensys.net/public/${pname}/raw/names/${pname}.tar.gz/versions/${version}/${pname}-${version}.tar.gz";
    hash = "sha256-8xkALHtk2U4HpLwfpO0ecFBJsYDpqjuJsKzOWr6dGZY=";
  };

  https://artifacts.consensys.net/public/web3signer/raw/names/web3signer.tar.gz/versions/24.1.0/web3signer-24.1.0.tar.gz

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    mkdir -p $out/bin
    cp -r bin $out/
    mkdir -p $out/lib
    cp -r lib $out/
    wrapProgram $out/bin/${pname} --set JAVA_HOME "${jre}"
  '';

  meta = with lib; {
    description = "Web3Signer is an open-source signing service capable of signing on multiple platforms (Ethereum1 and 2, Filecoin) using private keys stored in an external vault, or encrypted on a disk";
    homepage = "https://github.com/ConsenSys/web3signer";
    license = licenses.apsl20;
    mainProgram = "web3signer";
    platforms = ["x86_64-linux"];
    sourceProvenance = with sourceTypes; [binaryBytecode];
  };
}
