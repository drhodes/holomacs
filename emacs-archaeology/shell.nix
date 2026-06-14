{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.minimal-bootstrap.gcc46
    pkgs.gnumake
    pkgs.ncurses5
  ];
}
