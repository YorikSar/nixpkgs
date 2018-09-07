{ stdenv, fetchurl, makeDesktopItem, makeWrapper

# From Google Chrome
# Linked dynamic libraries.
, glib, fontconfig, freetype, pango, cairo, libX11, libXi, atk, gconf, nss, nspr
, libXcursor, libXext, libXfixes, libXrender, libXScrnSaver, libXcomposite, libxcb
, alsaLib, libXdamage, libXtst, libXrandr, expat, cups
, dbus_libs, gtk2, gdk_pixbuf, gcc-unwrapped, at-spi2-atk
, kerberos

# Will crash without.
, systemd

# Loaded at runtime.
, libexif

# For Minecraft itself
, openjdk
, flite
, libGLU_combined, openal
, pulseSupport ? true, libpulseaudio ? null
}:
with stdenv.lib;

assert pulseSupport -> libpulseaudio != null;

let
  exe = "minecraft-launcher";
  desktopItem = makeDesktopItem {
    name = "minecraft";
    exec = "$exe";
    icon = "minecraft";
    comment = "A sandbox-building game";
    desktopName = "Minecraft";
    genericName = "minecraft";
    categories = "Game;";
  };
  deps = [
    # From Google Chrome
    glib fontconfig freetype pango cairo libX11 libXi atk gconf nss nspr
    libXcursor libXext libXfixes libXrender libXScrnSaver libXcomposite libxcb
    alsaLib libXdamage libXtst libXrandr expat cups
    dbus_libs gdk_pixbuf gcc-unwrapped.lib
    systemd
    libexif
    at-spi2-atk
    gtk2
  ] ++ optional pulseSupport libpulseaudio
    # For Minecraft itself
    ++ [ flite libGLU_combined openal ];

in stdenv.mkDerivation rec {
  name = "minecraft-launcher-${version}";
  version = "2.1.1349";

  src = fetchurl {
    url = "https://launcher.mojang.com/download/Minecraft.tar.gz";
    sha256 = "16sl3kkx9xzxjxc46j1hgqr688m06y9fyxnki8ppgwzk2bwhsgm2";
  };

  phases = "installPhase";

  buildInputs = [ makeWrapper ];

  rpath = makeLibraryPath deps;
  binpath = makeBinPath [ openjdk openal ];

  installPhase = ''
    set -x
    mkdir -pv $out
    tar -xf $src --strip-components=1 -C $out

    patchelf --set-rpath $out:$rpath $out/launcher
    for elf in $out/{chrome-sandbox,launcher}; do
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $elf
    done

    makeWrapper "$out/launcher" "$out/${exe}" \
      --prefix LD_LIBRARY_PATH : "${rpath}" \
      --prefix PATH            : "${binpath}"

    mkdir -p $out/share/applications
    ln -s ${desktopItem}/share/applications/* $out/share/applications/

    set +x
  '';

  meta = {
      description = "A sandbox-building game";
      homepage = http://www.minecraft.net;
      maintainers = with stdenv.lib.maintainers; [ cpages ryantm ];
      license = stdenv.lib.licenses.unfreeRedistributable;
  };
}
