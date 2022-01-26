{ lib
, stdenv
, fetchFromGitLab
, glib
, meson
, ninja
, libmaxminddb
, pkg-config
, ronn
}:
let
  mkDerivations = targetLists: drvArgs @ { src, nativeBuildInputs, ... }:
    let
      # First derivation only runs meson to generate ninja files
      configureDrv = stdenv.mkDerivation {
        name = "configure";
        inherit src nativeBuildInputs;

        dontBuild = true;
        installPhase = "cp -r ../ $out/";
      };
      copyFromDrv = drv: "tar -xvf ${drv} -C $sourceRoot/build";
      # List of derivations that build parts of the graph according to targetLists
      buildDrv = builtins.foldl'
        (prev: targetList: stdenv.mkDerivation {
          name = "build.tar";
          src = configureDrv;
          inherit nativeBuildInputs;

          # Unpack whatever has already been built on previous step
          # We cannot run builds in parallel until we figure out how to merge Ninja's data files
          postUnpack = if prev != null then copyFromDrv prev else "";
          configurePhase = "cd build";
          preBuild = "ninjaFlagsArray+=(${builtins.concatStringsSep " " targetList})";
          # using tar here to preserve timestamps on files that Ninja verifies in deps and log
          installPhase = "tar -cvf $out ipcalc.p .ninja_deps .ninja_log";
        })
        null
        targetLists;
    in
    # Final derivation collects everything together and runs linker
    stdenv.mkDerivation (drvArgs // {
      src = configureDrv;

      postUnpack = copyFromDrv buildDrv;
      # reconfigure Ninja to point to proper output directories for installation
      preConfigure = "mesonFlagsArray+=(--reconfigure)";
    });

  # As an example, split object files in two lists, leaving link step to final derivation
  splitTargetLists = [
    [
      "ipcalc.p/ipcalc-utils.c.o"
      "ipcalc.p/ipcalc-maxmind.c.o"
      "ipcalc.p/ipcalc-reverse.c.o"
    ]
    [
      "ipcalc.p/ipv6.c.o"
      "ipcalc.p/deaggregate.c.o"
      "ipcalc.p/netsplit.c.o"
      "ipcalc.p/ipcalc.c.o"
    ]
  ];
in
mkDerivations splitTargetLists rec {
  pname = "ipcalc";
  version = "1.0.1";

  src = fetchFromGitLab {
    owner = "ipcalc";
    repo = "ipcalc";
    rev = version;
    sha256 = "0qg516jv94dlk0qj0bj5y1dd0i31ziqcjd6m00w8xp5wl97bj2ji";
  };

  nativeBuildInputs = [
    glib
    meson
    ninja
    pkg-config
    libmaxminddb
    ronn
  ];

  meta = with lib; {
    description = "Simple IP network calculator";
    homepage = "https://gitlab.com/ipcalc/ipcalc";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ ];
  };
}
