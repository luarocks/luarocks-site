{
  description = "Luarocks site";

  inputs = {

    nixpkgs.url = "github:teto/nixpkgs/nixos-unstable";

  };

  outputs = { self, nixpkgs }: let 
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system}.pkgs;

  in {

    devShells.x86_64-linux.default = pkgs.mkShell {
      name = "luarocks-site";

      # with pkgs;
      buildInputs =  let
        luaEnv = pkgs.lua5_1.withPackages(lp: [
          lp.luaexpat
          lp.busted
          lp.luarocks
          lp.moonscript # provides moonc compiler
          # lp.toto
        ]);
      in
      [
        pkgs.tup
        # pkgs.lua5_1.pkgs.luarocks
        luaEnv
        pkgs.sassc
        # expat.dev # for the lua
        pkgs.openresty
        pkgs.discount # for 
        pkgs.nodePackages.coffee-script
      ];

      # TODO we should not need to export EXPAT, the lua env should be able to find the luaexpat installed by nix
      # TODO the makefile contains:
      # CURRENT_DB=$(shell /usr/local/openresty/luajit/bin/luajit -e 'print(require("lapis.config").get().postgres.database)')
# CURRENT_ENVIRONMENT=$(shell /usr/local/openresty/luajit/bin/luajit -e 'print(require("lapis.config").get()._name)')
      # we should be able to do better
      shellHook = let 
        luarocksContent = pkgs.lua.pkgs.luaLib.generateLuarocksConfig {

          externalDeps = [ 
              { name = "EXPAT"; dep = pkgs.expat; }
              { name = "CRYPTO"; dep = pkgs.openssl; }
              { name = "OPENSSL"; dep = pkgs.openssl; }
              { name = "ZLIB"; dep = pkgs.zlib; }
          ];

          extraVariables  = {};
          requiredLuaRocks = [];
          rocksSubdir = "rocks-subdir";
        }; 
        luarocksConfigFile = pkgs.writeTextFile {
          text = luarocksContent;
          name = "luarocks-config" ;
        };
      in ''
        export LUAROCKS_CONFIG=${luarocksConfigFile}

        echo "You need a postgres server"
        echo "Read README for next steps"
        echo "make install_deps"
      '';

    };
  };
}
