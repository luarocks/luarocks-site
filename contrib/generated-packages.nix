/* pkgs/development/lua-modules/generated-packages.nix is an auto-generated file -- DO NOT EDIT!
Regenerate it with: nix run nixpkgs#update-luarocks-packages
You can customize the generated packages in pkgs/development/lua-modules/overrides.nix
*/

{ stdenv, lib, fetchurl, fetchgit, callPackage, ... } @ args:
final: prev:
{
ansicolors = callPackage({ buildLuarocksPackage, fetchurl, lua, luaOlder }:
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

bcrypt = callPackage({ buildLuarocksPackage, fetchgit, fetchurl, lua, luaOlder }:
buildLuarocksPackage {
  pname = "bcrypt";
  version = "2.3-1";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/bcrypt-2.3-1.rockspec";
    sha256 = "1zjy7sflyd50jvp603hmw0sg3rw5xyray0spzv5x5ky9hxivcdrf";
  }).outPath;
  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "https://github.com/mikejsavage/lua-bcrypt.git",
  "rev": "8914833d1bdc86af9b10454a22a6c042e1ac29ba",
  "date": "2022-04-09T19:53:15+03:00",
  "path": "/nix/store/dw74i71i3ydkiysf41yadz6g0bvfphnp-lua-bcrypt",
  "sha256": "0sj0nzppqw6b98g8mx9q856frlwa3j5vddrsr5gkzpn36xpl1py1",
  "hash": "sha256-wd9AbzfD3j9fyTq3toscitPsTEE49YoeSstwfO+3QGo=",
  "fetchLFS": false,
  "fetchSubmodules": true,
  "deepClone": false,
  "leaveDotGit": false
}
 '') ["date" "path" "sha256"]) ;

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua ];

  meta = {
    homepage = "http://github.com/mikejsavage/lua-bcrypt";
    description = "A Lua wrapper for bcrypt";
    license.fullName = "ISC";
  };
}) {};

cloud_storage = callPackage({ buildLuarocksPackage, date, fetchgit, fetchurl, lua, lua-cjson, luaOlder, luaexpat, luaossl, luasocket, mimetypes }:
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
 '') ["date" "path" "sha256"]) ;

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ date lua lua-cjson luaexpat luaossl luasocket mimetypes ];

  meta = {
    homepage = "https://github.com/leafo/cloud_storage.git";
    description = "Access Google Cloud Storage from Lua";
    license.fullName = "MIT";
  };
}) {};

date = callPackage({ buildLuarocksPackage, fetchgit, fetchurl, lua, luaAtLeast, luaOlder }:
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
 '') ["date" "path" "sha256"]) ;

  disabled = (luaOlder "5.0") || (luaAtLeast "5.5");
  propagatedBuildInputs = [ lua ];

  meta = {
    homepage = "https://github.com/Tieske/date";
    description = "Date & Time module for Lua 5.x";
    license.fullName = "MIT";
  };
}) {};

etlua = callPackage({ buildLuarocksPackage, fetchgit, fetchurl, lua, luaOlder }:
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
 '') ["date" "path" "sha256"]) ;

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua ];

  meta = {
    homepage = "https://github.com/leafo/etlua";
    description = "Embedded templates for Lua";
    license.fullName = "MIT";
  };
}) {};

lapis = callPackage({ ansicolors, argparse, buildLuarocksPackage, date, etlua, fetchgit, fetchurl, loadkit, lpeg, lua, lua-cjson, luaossl, luasocket, pgmoon }:
buildLuarocksPackage {
  pname = "lapis";
  version = "1.16.0-1";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/lapis-1.16.0-1.rockspec";
    sha256 = "0rqq02kpqawhpwii8i4vziv0cfc9ifz8w8pgi19wf8d0p3yhczig";
  }).outPath;
  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "https://github.com/leafo/lapis.git",
  "rev": "2871ab9661a97f0ce3f622e9d9504a596a83c727",
  "date": "2023-11-03T10:32:22-07:00",
  "path": "/nix/store/r4kkw2gg5m0hlqnh0qdshmj8y83i3xxa-lapis",
  "sha256": "08yh7ijqma564lkfb2dvh5hbik5hdcf9mih5f5rlnm05jkamrx77",
  "hash": "sha256-5/Rc1ZQFVEtzcQXGmhxrsMy4YIG7ieUmJaaoimU80CM=",
  "fetchLFS": false,
  "fetchSubmodules": true,
  "deepClone": false,
  "leaveDotGit": false
}
 '') ["date" "path" "sha256"]) ;

  propagatedBuildInputs = [ ansicolors argparse date etlua loadkit lpeg lua lua-cjson luaossl luasocket pgmoon ];

  meta = {
    homepage = "http://leafo.net/lapis";
    description = "A web framework for MoonScript & Lua";
    license.fullName = "MIT";
  };
}) {};

lapis-console = callPackage({ buildLuarocksPackage, fetchgit, fetchurl, lapis, lua }:
buildLuarocksPackage {
  pname = "lapis-console";
  version = "1.2.0-1";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/lapis-console-1.2.0-1.rockspec";
    sha256 = "1947hsr891z47hwxynrcx6binzwshg3rr81wzcjszybhqv7hprkp";
  }).outPath;
  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "https://github.com/leafo/lapis-console.git",
  "rev": "b76ad976086e2ddb87603a3c8a31a8efa483450a",
  "date": "2021-01-25T08:51:59-08:00",
  "path": "/nix/store/rapxaa6ca3grwxbxpyhbcha2048vzcp8-lapis-console",
  "sha256": "0344p3cr29c5lzp1whxsh4fsyp2bk7f78wzqx5h9y0234k20jbc1",
  "hash": "sha256-gS0JxCRDAJ9g6fhzdNyZS1yvHYG6Qx7up4Ulkdm4hAw=",
  "fetchLFS": false,
  "fetchSubmodules": true,
  "deepClone": false,
  "leaveDotGit": false
}
 '') ["date" "path" "sha256"]) ;

  disabled = (lua.luaversion != "5.1");
  propagatedBuildInputs = [ lapis lua ];

  meta = {
    homepage = "https://github.com/leafo/lapis-console.git";
    description = "An interactive web based console for Lapis";
    license.fullName = "MIT";
  };
}) {};

lapis-exceptions = callPackage({ buildLuarocksPackage, fetchgit, fetchurl, lapis, lua, tableshape }:
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
 '') ["date" "path" "sha256"]) ;

  disabled = (lua.luaversion != "5.1");
  propagatedBuildInputs = [ lapis lua tableshape ];

  meta = {
    homepage = "https://github.com/leafo/lapis-exceptions.git";
    description = "Track Lapis exceptions to database and email when they happen";
    license.fullName = "MIT";
  };
}) {};

mailgun = callPackage({ buildLuarocksPackage, fetchgit, fetchurl, lpeg, lua, lua-cjson, luaOlder, luasec, luasocket }:
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
 '') ["date" "path" "sha256"]) ;

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lpeg lua lua-cjson luasec luasocket ];

  meta = {
    homepage = "https://github.com/leafo/lua-mailgun";
    description = "Send email with Mailgun";
    license.fullName = "MIT";
  };
}) {};

mimetypes = callPackage({ buildLuarocksPackage, fetchurl, lua, luaOlder }:
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

pgmoon = callPackage({ buildLuarocksPackage, fetchgit, fetchurl, lpeg, lua, luaOlder }:
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
 '') ["date" "path" "sha256"]) ;

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lpeg lua ];

  meta = {
    homepage = "https://github.com/leafo/pgmoon";
    description = "Postgres driver for OpenResty and Lua";
    license.fullName = "MIT";
  };
}) {};

tableshape = callPackage({ buildLuarocksPackage, fetchgit, fetchurl, lua, luaOlder }:
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
 '') ["date" "path" "sha256"]) ;

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
