{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;

let
  static = import ./static.nix { inherit nixpkgs; };
  pages = import ./pages { inherit nixpkgs; };
  blog-posts = import ./blog-posts.nix { inherit nixpkgs; };
in
symlinkJoin {
  name = "me-nix";
  paths = map (s: s.forest) (builtins.concatMap builtins.attrValues [
    blog-posts.outputs
    static.outputs
    pages.outputs
  ]);
}
