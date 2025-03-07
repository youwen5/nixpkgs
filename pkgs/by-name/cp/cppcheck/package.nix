{
  lib,
  stdenv,
  fetchFromGitHub,

  docbook_xml_dtd_45,
  docbook_xsl,
  installShellFiles,
  libxslt,
  pcre,
  pkg-config,
  python3,
  which,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "cppcheck";
  version = "2.16.1";

  outputs = [
    "out"
    "man"
  ];

  src = fetchFromGitHub {
    owner = "danmar";
    repo = "cppcheck";
    rev = finalAttrs.version;
    hash = "sha256-rx/JtpNPo8uDr4MR6h0ANK0erK8oMhlJp+4BQtc/poc=";
  };

  nativeBuildInputs = [
    docbook_xml_dtd_45
    docbook_xsl
    installShellFiles
    libxslt
    pkg-config
    python3
    which
  ];

  buildInputs = [
    pcre
    (python3.withPackages (ps: [ ps.pygments ]))
  ];

  makeFlags = [
    "PREFIX=$(out)"
    "MATCHCOMPILER=yes"
    "FILESDIR=$(out)/share/cppcheck"
    "HAVE_RULES=yes"
  ];

  enableParallelBuilding = true;
  strictDeps = true;

  # test/testcondition.cpp:4949(TestCondition::alwaysTrueContainer): Assertion failed.
  doCheck = !(stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isAarch64);
  doInstallCheck = true;

  postPatch = ''
    substituteInPlace Makefile \
      --replace 'PCRE_CONFIG = $(shell which pcre-config)' 'PCRE_CONFIG = $(PKG_CONFIG) libpcre'
  '';

  postBuild = ''
    make DB2MAN=${docbook_xsl}/xml/xsl/docbook/manpages/docbook.xsl man
  '';

  postInstall = ''
    installManPage cppcheck.1
  '';

  installCheckPhase = ''
    runHook preInstallCheck

    echo 'int main() {}' > ./installcheck.cpp
    $out/bin/cppcheck ./installcheck.cpp > /dev/null

    runHook postInstallCheck
  '';

  meta = {
    description = "Static analysis tool for C/C++ code";
    longDescription = ''
      Check C/C++ code for memory leaks, mismatching allocation-deallocation,
      buffer overruns and more.
    '';
    homepage = "http://cppcheck.sourceforge.net";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [
      joachifm
      paveloom
    ];
    platforms = lib.platforms.unix;
  };
})
