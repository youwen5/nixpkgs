{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  qtbase,
  qtmultimedia,
  qscintilla,
  bison,
  flex,
  eigen,
  boost,
  libGLU,
  libGL,
  glew,
  opencsg,
  cgal_4,
  mpfr,
  gmp,
  glib,
  pkg-config,
  harfbuzz,
  gettext,
  freetype,
  fontconfig,
  double-conversion,
  lib3mf,
  libzip,
  mkDerivation,
  qtmacextras,
  qmake,
  spacenavSupport ? stdenv.hostPlatform.isLinux,
  libspnav,
  wayland,
  wayland-protocols,
  wrapGAppsHook3,
  qtwayland,
  cairo,
  openscad,
  runCommand,
}:

mkDerivation rec {
  pname = "openscad";
  version = "2021.01";

  src = fetchFromGitHub {
    owner = "openscad";
    repo = "openscad";
    rev = "${pname}-${version}";
    sha256 = "sha256-2tOLqpFt5klFPxHNONnHVzBKEFWn4+ufx/MU+eYbliA=";
  };

  patches = [
    (fetchpatch {
      name = "CVE-2022-0496.patch";
      url = "https://github.com/openscad/openscad/commit/00a4692989c4e2f191525f73f24ad8727bacdf41.patch";
      sha256 = "sha256-q3SLj2b5aM/IQ8vIDj4iVcwCajgyJ5juNV/KN35uxfI=";
    })
    (fetchpatch {
      name = "CVE-2022-0497.patch";
      url = "https://github.com/openscad/openscad/commit/84addf3c1efbd51d8ff424b7da276400bbfa1a4b.patch";
      sha256 = "sha256-KNEVu10E2d4G2x+FJcuHo2tjD8ygMRuhUcW9NbN98bM=";
    })
  ];

  postPatch = ''
    substituteInPlace src/FileModule.cc \
      --replace-fail 'fs::is_regular' 'fs::is_regular_file'
  '';

  nativeBuildInputs = [
    bison
    flex
    pkg-config
    gettext
    qmake
    wrapGAppsHook3
  ];

  buildInputs =
    [
      eigen
      boost
      glew
      opencsg
      cgal_4
      mpfr
      gmp
      glib
      harfbuzz
      lib3mf
      libzip
      double-conversion
      freetype
      fontconfig
      qtbase
      qtmultimedia
      qscintilla
      cairo
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      libGLU
      libGL
      wayland
      wayland-protocols
      qtwayland
    ]
    ++ lib.optional stdenv.hostPlatform.isDarwin qtmacextras
    ++ lib.optional spacenavSupport libspnav;

  qmakeFlags =
    [
      "VERSION=${version}"
      "LIB3MF_INCLUDEPATH=${lib3mf.dev}/include/lib3mf/Bindings/Cpp"
      "LIB3MF_LIBPATH=${lib3mf}/lib"
    ]
    ++ lib.optionals spacenavSupport [
      "ENABLE_SPNAV=1"
      "SPNAV_INCLUDEPATH=${libspnav}/include"
      "SPNAV_LIBPATH=${libspnav}/lib"
    ];

  enableParallelBuilding = true;

  preBuild = ''
    make objects/parser.cxx
  '';

  postInstall = lib.optionalString stdenv.hostPlatform.isDarwin ''
    mkdir $out/Applications
    mv $out/bin/*.app $out/Applications
    rmdir $out/bin || true

    mv --target-directory=$out/Applications/OpenSCAD.app/Contents/Resources \
      $out/share/openscad/{examples,color-schemes,locale,libraries,fonts,templates}

    rmdir $out/share/openscad
  '';

  meta = {
    description = "3D parametric model compiler";
    longDescription = ''
      OpenSCAD is a software for creating solid 3D CAD objects. It is free
      software and available for Linux/UNIX, MS Windows and macOS.

      Unlike most free software for creating 3D models (such as the famous
      application Blender) it does not focus on the artistic aspects of 3D
      modelling but instead on the CAD aspects. Thus it might be the
      application you are looking for when you are planning to create 3D models of
      machine parts but pretty sure is not what you are looking for when you are more
      interested in creating computer-animated movies.
    '';
    homepage = "https://openscad.org/";
    license = lib.licenses.gpl2;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [
      bjornfor
      raskin
      gebner
    ];
    mainProgram = "openscad";
  };

  passthru.tests = {
    lib3mf_support =
      runCommand "${pname}-lib3mf-support-test"
        {
          nativeBuildInputs = [ openscad ];
        }
        ''
          echo "cube([1, 1, 1]);" | openscad -o cube.3mf -
          echo "import(\"cube.3mf\");" | openscad -o cube-import.3mf -
          mv cube-import.3mf $out
        '';
  };
}
