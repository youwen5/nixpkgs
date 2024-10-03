{
  pkg-config,
  stdenv,
  wayland,
  wayland-protocols,
  wayland-scanner,
  libxkbcommon,
  fetchFromGitea,
  libxcrypt,
  pam,
}:
stdenv.mkDerivation {
  name = "wlock";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "sewn";
    repo = "wlock";
    rev = "be975445fa0da7252f8e13b610c518dd472652d0";
    hash = "sha256-Xt7Q51RhFG+UXYukxfORIhc4Df86nxtpDhAhaSmI38
A=";
  };

  buildInputs = [
    wayland
    wayland-protocols
    libxkbcommon
    libxcrypt
    pam
  ];

  nativeBuildInputs = [
    pkg-config
    wayland-scanner
  ];

  installPhase = ''
    mkdir -p $out/bin
    mv wlock $out/bin
  '';
}
