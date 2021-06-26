{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;

let
  removeRedundantSlashes = s:
    builtins.concatStringsSep "/" (
      builtins.filter (x: builtins.isString x && x != "") (
        builtins.split "/" "/hello/there//you.png"));

  mkStatic = { rel, minify ? false }:
    let
      fullPath = "${builtins.toString ./static}/${rel}";
    in
    mkForest {
      file = builtins.path { path = fullPath; };
      rel = "/static/${rel}";
    };

  mkForest = { rel, file }:
    {
      blogPath = rel;
      forest =
        runCommand "forest-${rel}" {} ''
          mkdir -p $out/'${builtins.dirOf rel}'
          ln -s '${file}' $out/'${rel}'
        '';
    };
in
{
  inherit mkStatic;
  outputs = {
    profileImage = mkStatic { rel = "profile.jpg"; };
    css = mkStatic { rel = "style.css"; };
    js = mkStatic { rel = "app.js"; };
    faviconDir = mkStatic { rel = "favicon"; };
    faviconJpeg = mkStatic { rel = "favicon.jpeg"; };
    cvpdf = mkStatic { rel = "dylant-cv.pdf"; };
  };
}
