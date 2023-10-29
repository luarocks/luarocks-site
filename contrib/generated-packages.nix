/* pkgs/development/lua-modules/generated-packages.nix is an auto-generated file -- DO NOT EDIT!
Regenerate it with: nix run nixpkgs#update-luarocks-packages
You can customize the generated packages in pkgs/development/lua-modules/overrides.nix
*/

{ stdenv, lib, fetchurl, fetchgit, callPackage, ... } @ args:
final: prev:
{
ansicolors = callPackage({ fetchurl, lua, luaOlder, buildLuarocksPackage }:
buildLuarocksPackage {
  pname = "ansicolors";
  version = "1.0.2-3";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/ansicolors-1.0.2-3.rockspec";
    sha256 = "19y962xdx5ldl3596ywdl7n825dffz9al6j6rx6pbgmhb7pi8s5v";
  }).outPath;
  src = fetchurl {
    url    = "https://github.com/kikito/ansicolors.lua/archive/v1.0.2.tar.gz";
    sha256 = "0r4xi57njldmar9pn77l0vr5701rpmilrm51spv45lz0q9js8xps";
  };

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua ];

  meta = {
    homepage = "https://github.com/kikito/ansicolors.lua";
    description = "Library for color Manipulation.";
    license.fullName = "MIT <http://opensource.org/licenses/MIT>";
  };
}) {};

cloud_storage = callPackage({ lua, buildLuarocksPackage, luaexpat, date, lua-cjson, luaossl, mimetypes, luasocket, luaOlder, fetchgit }:
buildLuarocksPackage {
  pname = "cloud_storage";
  version = "1.3.0-1";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/cloud_storage-1.3.0-1.rockspec";
    sha256 = "0fhr4f4m9smwv4z2pq6l0gwf4rfna21fi4z7qb80hwvl5z8j1yvh";
  }).outPath;
  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "https://github.com/leafo/cloud_storage.git",
  "rev": "061c3fabf7e02430644c0e237356324860563ff9",
  "date": "2022-11-18T12:35:24-08:00",
  "path": "/nix/store/cs5zhgyxhrnvchjn31yzjn6vwjyyvin1-cloud_storage",
  "sha256": "1r2mk3ik6gmfssadd5xhpjdqghqgrw5i4pqr6v4a2sh8wmsyj742",
  "hash": "sha256-ghzpdeUIaqHINhlfEgvPD8OHm7ywl9aU1q4+M+OYVeQ=",
  "fetchLFS": false,
  "fetchSubmodules": true,
  "deepClone": false,
  "leaveDotGit": false
}
 '') ["date" "path"]) ;

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ date lua lua-cjson luaexpat luaossl luasocket mimetypes ];

  meta = {
    homepage = "git://github.com/leafo/cloud_storage.git";
    description = "Access Google Cloud Storage from Lua";
    license.fullName = "MIT";
  };
}) {};

date = callPackage({ luaOlder, lua, fetchgit, buildLuarocksPackage, luaAtLeast }:
buildLuarocksPackage {
  pname = "date";
  version = "2.2.1-1";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/date-2.2.1-1.rockspec";
    sha256 = "0yksq18pmsczf8w3n3qdircyk1sy1dmcfkf2nszrsx44sw27y94a";
  }).outPath;
  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "https://github.com/Tieske/date.git",
  "rev": "2be47e4bca392c542509ac55d33d64bd60fc9402",
  "date": "2023-09-06T20:09:59+02:00",
  "path": "/nix/store/h2pq6c5cyqccy61sqy86ifbr2a5fibph-date",
  "sha256": "18nqmkvz91bvh5k77p8qym05k10jqd2f21b9mlyigwncby9ybriz",
  "hash": "sha256-P+blk1/M8hc9rWkF4UTDEoRZQPUY3XNmgXuF9Pes2KI=",
  "fetchLFS": false,
  "fetchSubmodules": true,
  "deepClone": false,
  "leaveDotGit": false
}
 '') ["date" "path"]) ;

  disabled = (luaOlder "5.0") || (luaAtLeast "5.5");
  propagatedBuildInputs = [ lua ];

  meta = {
    homepage = "https://github.com/Tieske/date";
    description = "Date & Time module for Lua 5.x";
    license.fullName = "MIT";
  };
}) {};

etlua = callPackage({ lua, buildLuarocksPackage, luaOlder, fetchgit }:
buildLuarocksPackage {
  pname = "etlua";
  version = "1.3.0-1";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/etlua-1.3.0-1.rockspec";
    sha256 = "1g98ibp7n2p4js39din2balncjnxxdbaq6msw92z072s2cccx9cf";
  }).outPath;
  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "https://github.com/leafo/etlua.git",
  "rev": "8dda2e5aeb4413446172a562a9a374b700054836",
  "date": "2019-08-02T18:07:22-07:00",
  "path": "/nix/store/kk7sib6lwra0wyf6yjc8shkny7b5qnm7-etlua",
  "sha256": "0ns7vvzslxhx39xwhxzi6cwkk2vcxidxidgysr03sq47h8daspig",
  "hash": "sha256-L16tGoKHYD1A1v612FvsbIs5OTPxd8h7Gh12qv/eR1s=",
  "fetchLFS": false,
  "fetchSubmodules": true,
  "deepClone": false,
  "leaveDotGit": false
}
 '') ["date" "path"]) ;

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua ];

  meta = {
    homepage = "https://github.com/leafo/etlua";
    description = "Embedded templates for Lua";
    license.fullName = "MIT";
  };
}) {};

lapis = callPackage({ argparse, lua-cjson, date, luaossl, lua, fetchgit, luasocket, lpeg, ansicolors, loadkit, pgmoon, etlua, buildLuarocksPackage }:
buildLuarocksPackage {
  pname = "lapis";
  version = "1.15.0-1";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/lapis-1.15.0-1.rockspec";
    sha256 = "1gzgc446q4aab9ly68niai7r7636l3kylzna3qj6sh6w54c8kgi2";
  }).outPath;
  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "https://github.com/leafo/lapis.git",
  "rev": "1cbd6cc76818eaac500bb427f2da445b7cdb4b73",
  "date": "2023-10-17T00:40:34-07:00",
  "path": "/nix/store/i1s0gcddzpswi2q9bcar53pasrrlmv7p-lapis",
  "sha256": "1zj5c2j9g6fd66j0jg9pf5962razgndwfk154z3b5jkapln4q4rh",
  "hash": "sha256-MBNMLL1qyrLGJyVMx5t9X2VhUnE3PQmkMc2Zl6RgRf4=",
  "fetchLFS": false,
  "fetchSubmodules": true,
  "deepClone": false,
  "leaveDotGit": false
}
 '') ["date" "path"]) ;

  propagatedBuildInputs = [ ansicolors argparse date etlua loadkit lpeg lua lua-cjson luaossl luasocket pgmoon ];

  meta = {
    homepage = "http://leafo.net/lapis";
    description = "A web framework for MoonScript & Lua";
    license.fullName = "MIT";
  };
}) {};

lapis-exceptions = callPackage({ tableshape, lapis, buildLuarocksPackage, lua, fetchgit }:
buildLuarocksPackage {
  pname = "lapis-exceptions";
  version = "2.4.0-1";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/lapis-exceptions-2.4.0-1.rockspec";
    sha256 = "0rbgqw64wi1z9w0s4qp6wkz66jc45algsny8xmirqaahfbs4wp2v";
  }).outPath;
  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "https://github.com/leafo/lapis-exceptions.git",
  "rev": "afaf2cbc62a7b3957063d94c114c90219dbdd64a",
  "date": "2023-07-20T15:24:33-07:00",
  "path": "/nix/store/j6pxwm7hni9dmj83664pd35pv189fj2g-lapis-exceptions",
  "sha256": "056aflnwmjgw28zhh55x129k7qxvnbndmmrxhh18m8213qlliglh",
  "hash": "sha256-kL5IKR5BoIoChD3X2uyyu+Mzkwi9FAg/EvzJyi11yhQ=",
  "fetchLFS": false,
  "fetchSubmodules": true,
  "deepClone": false,
  "leaveDotGit": false
}
 '') ["date" "path"]) ;

  disabled = (lua.luaversion != "5.1");
  propagatedBuildInputs = [ lapis lua tableshape ];

  meta = {
    homepage = "git://github.com/leafo/lapis-exceptions.git";
    description = "Track Lapis exceptions to database and email when they happen";
    license.fullName = "MIT";
  };
}) {};

mailgun = callPackage({ lua, fetchgit, luaOlder, luasec, luasocket, lpeg, buildLuarocksPackage, lua-cjson }:
buildLuarocksPackage {
  pname = "mailgun";
  version = "1.2.0-1";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/mailgun-1.2.0-1.rockspec";
    sha256 = "1vb8mgxfqxq8k6aabhf1183gq6b1pyvr8mjgkk7fac43bfy3v8iv";
  }).outPath;
  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "https://github.com/leafo/lua-mailgun.git",
  "rev": "e8edd4d50f9c8f181a01cf166e7031aff6c7f716",
  "date": "2022-04-08T10:09:23-07:00",
  "path": "/nix/store/ppjnyknpa9d3jbwrvghv6x39cpr52azr-lua-mailgun",
  "sha256": "1d37hb8s6lrciimyyj8vsm3zpqlc81n8b7qvkkvdv9r1rimasm79",
  "hash": "sha256-6VStaswhp932nBufhWxAjOL7R9UbSe9rjCxTo9GCZ7Q=",
  "fetchLFS": false,
  "fetchSubmodules": true,
  "deepClone": false,
  "leaveDotGit": false
}
 '') ["date" "path"]) ;

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lpeg lua lua-cjson luasec luasocket ];

  meta = {
    homepage = "https://github.com/leafo/lua-mailgun";
    description = "Send email with Mailgun";
    license.fullName = "MIT";
  };
}) {};

mimetypes = callPackage({ lua, buildLuarocksPackage, luaOlder, fetchurl }:
buildLuarocksPackage {
  pname = "mimetypes";
  version = "1.0.0-3";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/mimetypes-1.0.0-3.rockspec";
    sha256 = "02f5x5pkz6fba71mp031arrgmddsyivn5fsa0pj3q3a7nxxpmnq9";
  }).outPath;
  src = fetchurl {
    url    = "https://github.com/lunarmodules/lua-mimetypes/archive/v1.0.0/lua-mimetypes-1.0.0.tar.gz";
    sha256 = "1rc5lnzvw4cg8wxn4w4sar2xgf5vaivdd2hgpxxcqfzzcmblg1zk";
  };

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua ];

  meta = {
    homepage = "https://github/lunarmodules/lua-mimetypes/";
    description = "A simple library for looking up the MIME types of files.";
    license.fullName = "MIT/X11";
  };
}) {};

pgmoon = callPackage({ lua, luaOlder, buildLuarocksPackage, lpeg, fetchgit }:
buildLuarocksPackage {
  pname = "pgmoon";
  version = "1.16.0-1";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/pgmoon-1.16.0-1.rockspec";
    sha256 = "0qibc6pbal0n5p7c0v0rxrc2b3qdkbbz5wpn4nihsv7vkhjaqhx8";
  }).outPath;
  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "https://github.com/leafo/pgmoon.git",
  "rev": "cd42b4a12ceae969db3f38bb2757ae738e4b0e32",
  "date": "2023-08-17T11:22:30-07:00",
  "path": "/nix/store/56pj043kgc7724aszqsxnxf3f2d1z754-pgmoon",
  "sha256": "1839sywh2d08kr52h4sswy6yfgk71zpa1qcfvxjqawwy3pfxmy4z",
  "hash": "sha256-n/ja3R2ec4Vl347hoO4PZz7njedaEyhKngg0AbnXaaA=",
  "fetchLFS": false,
  "fetchSubmodules": true,
  "deepClone": false,
  "leaveDotGit": false
}
 '') ["date" "path"]) ;

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lpeg lua ];

  meta = {
    homepage = "https://github.com/leafo/pgmoon";
    description = "Postgres driver for OpenResty and Lua";
    license.fullName = "MIT";
  };
}) {};

tableshape = callPackage({ luaOlder, buildLuarocksPackage, fetchgit, lua }:
buildLuarocksPackage {
  pname = "tableshape";
  version = "2.6.0-1";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/tableshape-2.6.0-1.rockspec";
    sha256 = "198hfddc1lnaxy21bp8nykb8paw5s1v653sl5s547yj3vmazzw2c";
  }).outPath;
  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "https://github.com/leafo/tableshape.git",
  "rev": "88755361cfeab725f193b98fbee3930cb5fb959c",
  "date": "2023-02-22T19:30:25-08:00",
  "path": "/nix/store/qmyzyvcfhfmcgaq19qh7a40kpq8670yz-tableshape",
  "sha256": "18g16alcxqyd4plk8c6zrign9ai745jnl5zs6jzrcjl98qz9n5md",
  "hash": "sha256-rRabPkaJSpa/NPoXamUhJ6pkX8zfMDTpJc3jzqgy4aE=",
  "fetchLFS": false,
  "fetchSubmodules": true,
  "deepClone": false,
  "leaveDotGit": false
}
 '') ["date" "path"]) ;

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua ];

  meta = {
    homepage = "https://github.com/leafo/tableshape";
    description = "Test the shape or structure of a Lua table";
    license.fullName = "MIT";
  };
}) {};


}
/* GENERATED - do not edit this file */
