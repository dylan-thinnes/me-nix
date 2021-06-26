{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;
with (import ./. {});

let static = import ../static.nix {};
    blog-posts = import ../blog-posts.nix {};
in
mkPage {
  title = "Blog";
  url = "/blog";
  rawContent = ''
    <h2>blog</h2>
    ${builtins.concatStringsSep "\n"
      (builtins.map (s: s.entry)
        (builtins.attrValues blog-posts.outputs))}
  '';
}
