{
  description = "Luarocks site";

  inputs = {

    nixpkgs.url = "github:teto/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (system:
        let

          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
                # openresty uses luajit so we need lua5.1
                luaEnv = pkgs.lua5_1.withPackages (lp: [
                  lp.luaexpat
                  lp.busted
                  lp.luarocks
                  lp.moonscript # provides moonc compiler
                  lp.lapis
                  lp.lapis-console
                  lp.lapis-exceptions
                  lp.tableshape
                  lp.mailgun
                  # cloudstorage / zipwriter

                ]);

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
                luarocksContent = pkgs.lua.pkgs.luaLib.generateLuarocksConfig {

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

              '';

          };
        }) // {

      # TODO make it possible to override different lua versions
      overlays.default = final: prev:
        let
          lua =
            let
              packageOverrides = prev.callPackage ./contrib/generated-packages.nix {
                # as done in nixpkgs
                inherit (lua.pkgs) callPackage;
              };
            in
            (prev.lua5_1.override { inherit packageOverrides; self = lua; });
        in
        {
          # luaPackages = lua.pkgs;
          lua5_1 = lua;
        };
    };
}
