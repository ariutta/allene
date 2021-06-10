{ pkgs ? import <nixpkgs> {}, stdenv ? pkgs.stdenv }:

pkgs.mkShell {
  #buildInputs = [ pkgs.argbash ];

  buildInputs = [

    pkgs.nodejs-16_x

    # node-gyp dependencies (node-gyp compiles C/C++ Addons)
    #   see https://github.com/nodejs/node-gyp#on-unix
    pkgs.python2

    pkgs.parallel

  ] ++ (if stdenv.isDarwin then [

    # more node-gyp dependencies
    # XCode Command Line Tools
    # TODO: do we need cctools?
    #pkgs.darwin.cctools

  ] else [

    # more node-gyp dependencies
    pkgs.gnumake

    # gcc and binutils disagree on the version of a
    # dependency, so we need to binutils-unwrapped.
    pkgs.gcc # also provides cc
    pkgs.binutils-unwrapped # provides ar

  ]);
}
