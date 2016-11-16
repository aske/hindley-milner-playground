with import <nixpkgs> {};

let rb-env = bundlerEnv {
    name = "hindley-milner-playground-gems";

    ruby = ruby_2_3;

    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset = ./gemset.nix;
  };

in
stdenv.mkDerivation rec {
  name = "hm-playground";
  src = ./hm.rb;
  buildInputs = [ ruby rb-env ];
}
