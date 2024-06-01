{
  description = "Luarocks site";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem 
      (system:
        let

          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };

            # TODO fix in the overlay directly
            mylzlib = pkgs.lua5_1.pkgs.lzlib.overrideAttrs(oa: {
                    # buildInputs = oa.buildInputs ++ [
                    #     pkgs.zlib.dev
                    #     pkgs.zlib.out
                    #   ];
                externalDeps = [
                  { name = "ZLIB"; dep = pkgs.zlib; }
                ];
                # extraVariables = rec {
                #   ZLIB_INCDIR = "${readline.dev}/include";
                #                   # { name = "ZLIB"; dep = pkgs.zlib; }
                # };

            });

            # myStruct = 
            # # else we get 'unpacker appears to have produced no directories'
            #   sourceRoot = ".";

          # openresty uses luajit so we need lua5.1
          luaEnv = pkgs.lua5_1.withPackages (lp: let

          in [
            lp.bcrypt
            lp.busted
            lp.cloud_storage
            lp.lapis
            lp.lapis-console
            lp.lapis-exceptions
            lp.luaexpat
            lp.luarocks
            lp.mailgun
            lp.moonscript # provides moonc compiler
            lp.tableshape
            lp.struct
            mylzlib
            # cloudstorage / zipwriter

          ]);

          lua = pkgs.lua5_1;
        in
        {

          packages = {

            lapis = pkgs.luaPackages.lapis;

            # https://nixos.org/manual/nixpkgs/unstable/#tester-runNixOSTest
            # https://nixos.org/manual/nixos/unstable/index.html#sec-calling-nixos-tests
            integration-tests =
              pkgs.testers.runNixOSTest (
                import contrib/nixos-test.nix { inherit luaEnv; }
              );

          };

          devShells.default = pkgs.mkShell {
            name = "luarocks-site";

            # with pkgs;
            buildInputs =
              [
                pkgs.luarocks-packages-updater
                pkgs.tup
                # pkgs.lua5_1.pkgs.luarocks
                # expat.dev # for the lua
                luaEnv
                pkgs.sassc
                pkgs.openresty
                pkgs.discount # for
                pkgs.nodePackages.coffee-script
              ];

            # TODO we should not need to export EXPAT, the lua env should be able to find the luaexpat installed by nix
            # TODO the makefile contains:
            # CURRENT_DB=$(shell /usr/local/openresty/luajit/bin/luajit -e 'print(require("lapis.config").get().postgres.database)')
            # CURRENT_ENVIRONMENT=$(shell /usr/local/openresty/luajit/bin/luajit -e 'print(require("lapis.config").get()._name)')
            # we should be able to do better
            shellHook =
              let
                luarocksContent = lua.pkgs.luaLib.generateLuarocksConfig {

                  externalDeps = [
                    { name = "EXPAT"; dep = pkgs.expat; }
                    { name = "CRYPTO"; dep = pkgs.openssl; }
                    { name = "OPENSSL"; dep = pkgs.openssl; }
                    { name = "ZLIB"; dep = pkgs.zlib; }
                  ];

                  extraVariables = { };
                  requiredLuaRocks = [ ];
                  rocksSubdir = "rocks-subdir";
                };
                # why do we need this already ?
                luarocksConfigFile = pkgs.writeTextFile {
                  text = luarocksContent;
                  name = "luarocks-config";
                };
                # export PATH="$PATH:~/.luarocks/bin"
                # export LUA_PATH='.luarocks/share/lua/5.1/?.lua;;'
                # export LAPIS_ENVIRONMENT to change environment
                # # luarocks path --tree ./.luarocks > .luarocks-init.sh
                # echo "sourcing .luarocks-init.sh"
                # source .luarocks-init.sh
                # echo "Read README for next steps"
                # echo "make install_deps"
              in
              ''
                export LUAROCKS_CONFIG=${luarocksConfigFile}

                # if your pgsql server is configured via TCP
                export PGHOST=localhost

                # Probably a fault in our lua infra
                export LUA_PATH="share/lua/${lua.luaversion}/?.lua;;"
                export LUA_CPATH="share/lua/${lua.luaversion}/?.lua;;"
                echo ${mylzlib.configFile}

              '';

          };
        }) // {

      # TODO make it possible to override different lua versions
      overlays.default = final: prev:
        let
          lua =
            let
              # TODO 
              
              generatedOverrides  = prev.callPackage ./contrib/generated-packages.nix {
                # as done in nixpkgs
                inherit (lua.pkgs) callPackage;
              };

              packageOverrides = final: prev: 
                let
                  result = (generatedOverrides final prev) ;
                in (result // {
                  # else we get 'unpacker appears to have produced no directories'
                  #   sourceRoot = ".";
                  struct = result.struct.overrideAttrs(oa: {
                    sourceRoot = ".";
                  });


                });
            in
            (prev.lua5_1.override { inherit packageOverrides; self = lua; });
        in
        {
          # luaPackages = lua.pkgs;
          lua5_1 = lua;
        };
    };
}
