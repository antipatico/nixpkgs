{
  stdenv,
  lib,
  pkgs,
  makeDesktopItem,
  requireFile,
  withMods ? true,
}:
let
  version = "1.0.1g";
  balatroExe = requireFile {
    name = "Balatro-${version}.exe";
    url = "https://store.steampowered.com/app/2379780/Balatro/";
    # Use `nix hash file --sri --type sha256` to get the correct hash
    hash = "sha256-X7t/T3lkLnDzewlmkxHjdePH/hlwoachuWfoUC4ntd0=";
  };
in
stdenv.mkDerivation {
  pname = "balatro";
  inherit version;
  nativeBuildInputs = with pkgs; [
    p7zip
    copyDesktopItems
  ];
  buildInputs = with pkgs; [ love ] ++ lib.optional withMods pkgs.lovely-injector;
  src = ./.;
  desktopItems = [
    (makeDesktopItem {
      name = "balatro";
      desktopName = "Balatro";
      exec = "balatro";
      keywords = [ "Game" ];
      categories = [ "Game" ];
      icon = "balatro";
    })
  ];
  buildPhase = ''
    runHook preBuild
    mkdir -p $out/share/{applications,icons}

    # "Patch" game and extract icon
    tmpdir=$(mktemp -d)
    7z x ${balatroExe} -o$tmpdir -y
    patch $tmpdir/globals.lua < $src/globals.patch
    patchedExe=$(mktemp -u).zip
    7z a $patchedExe $tmpdir/*
    cp $tmpdir/resources/textures/2x/balatro.png $out/share/icons/balatro.png

    # "Build" lovely game
    (cat ${pkgs.love}/bin/love;  cat $patchedExe) > $out/share/Balatro
    chmod +x $out/share/Balatro
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cat > $out/bin/balatro <<EOF
    #!${pkgs.stdenv.shell}
    ${
      if withMods then "LD_PRELOAD=${pkgs.lovely-injector}/lib/liblovely.so" else ""
    } exec $out/share/Balatro
    EOF
    chmod +x $out/bin/balatro
    runHook postInstall
  '';

  meta = {
    description = "The poker roguelike.";
    longDescription = ''
      Balatro is a hypnotically satisfying deckbuilder where you play illegal poker hands,
      discover game-changing jokers, and trigger adrenaline-pumping, outrageous combos.
    '';
    license = lib.licenses.unfree;
    homepage = "https://store.steampowered.com/app/2379780/Balatro/";
    maintainers = [ lib.maintainers.antipatico ];
    platforms = pkgs.love.meta.platforms;
  };
}
