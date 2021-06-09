{ pkgs ? import <nixpkgs> {}, stdenv ? pkgs.stdenv }:
let
  deps = import ./mynixpkgs/environments/node.nix;
in
  pkgs.mkShell {
    #buildInputs = deps ++ [ pkgs.argbash ];
    buildInputs = deps ++ [ pkgs.argbash ];
}
