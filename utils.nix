{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;

let sanitizeName = s:
      lib.strings.concatMapStrings
        (s: if lib.isList s then "-" else s)
        (builtins.split "[^[:alnum:]_-]+" s);
in
{ inherit sanitizeName; }
