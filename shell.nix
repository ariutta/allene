{ pkgs ? import <nixpkgs> {}, stdenv ? pkgs.stdenv }:
let
  deps = import ./mynixpkgs/environments/node.nix;
in
  pkgs.mkShell {
    buildInputs = deps ++ [
      pkgs.libxml2 # for xmllint
      pkgs.yarn
      # what about yarn2nix?
      #pkgs.yarn2nix
    ] ++ (if stdenv.isDarwin then [] else []);
}
