/* pkgs/development/lua-modules/generated-packages.nix is an auto-generated file -- DO NOT EDIT!
Regenerate it with:
nixpkgs$ ./maintainers/scripts/update-luarocks-packages

You can customize the generated packages in pkgs/development/lua-modules/overrides.nix
*/

{ self, stdenv, lib, fetchurl, fetchgit, callPackage, ... } @ args:
final: prev:
{
ansicolors = callPackage({ luaOlder, buildLuarocksPackage, fetchurl, lua }:
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

date = callPackage({ luaOlder, buildLuarocksPackage, lua, luaAtLeast, fetchgit }:
buildLuarocksPackage {
  pname = "date";
  version = "2.2-2";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/date-2.2-2.rockspec";
    sha256 = "0z2gb4rxfrkdx3zlysmlvfpm867fk0yq0bsn7yl789pvgf591l1x";
  }).outPath;
  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "https://github.com/Tieske/date.git",
  "rev": "e309741edc15bde2c884b0db09d8560848773b50",
  "date": "2023-06-19T14:52:25+02:00",
  "path": "/nix/store/mqai2jv2nligylw4bazrk1cw51q493mr-date",
  "sha256": "1s7bz4ivmpyc8mchp4nxm4b1yqf002ryjr30lwdswf64aljlx640",
  "hash": "sha256-gJhOJVXEOK4bp2Bk6bMAwGEfFqndkgtZRczfuiP56+g=",
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

lapis = callPackage({ ansicolors, lpeg, lua, lua-cjson, pgmoon, fetchgit, buildLuarocksPackage, date, argparse, loadkit, etlua, luaossl, luasocket }:
buildLuarocksPackage {
  pname = "lapis";
  version = "1.14.0-1";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/lapis-1.14.0-1.rockspec";
    sha256 = "1iax1n4nfk81vlslnb92wnpg03scci7p7983dwvkhk5nan63vnmh";
  }).outPath;
  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "https://github.com/leafo/lapis.git",
  "rev": "71ecc897e598db9860d9bb8caeb96fb81cb2e5fc",
  "date": "2023-04-18T13:04:53-07:00",
  "path": "/nix/store/192q6h3qdlapa8jchr4k342g307l1jwc-lapis",
  "sha256": "1zvdks9cvx6d3pmziblim1qkpswaxccbnqa17ciprrqg38y2j840",
  "hash": "sha256-gCApPBoP53wjO0Fhuxjrius7caiRrvjrHc30zZKebf8=",
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
pgmoon = callPackage({ luaOlder, buildLuarocksPackage, lpeg, lua, fetchgit }:
buildLuarocksPackage {
  pname = "pgmoon";
  version = "1.16.0-1";
  knownRockspec = (fetchurl {
    url    = "https://raw.githubusercontent.com/rocks-moonscript-org/moonrocks-mirror/master/pgmoon-1.16.0-1.rockspec";
    sha256 = "0qibc6pbal0n5p7c0v0rxrc2b3qdkbbz5wpn4nihsv7vkhjaqhx8";
  }).outPath;
  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "https://github.com/leafo/pgmoon.git",
  "rev": "7b7ef2a3f17d32881c61f0fb258d2ee01718942c",
  "date": "2022-11-22T14:49:59-08:00",
  "path": "/nix/store/jjyf1rij16mlqfx55rrpwadcnn8mf663-pgmoon",
  "sha256": "1ifivvkkqwcgp9s9ynlb394973mbhwgs9yvalbyn3170n78msacb",
  "hash": "sha256-iyld0bHghGH9omr7pB+Hq46TSBqLWp90uo9xPOfe0cU=",
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
 '') ["date" "path" "sha256"]) ;

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua ];

  meta = {
    homepage = "https://github.com/leafo/tableshape";
    description = "Test the shape or structure of a Lua table";
    license.fullName = "MIT";
  };
}) {};

  etlua = callPackage
    ({ lua, buildLuarocksPackage, fetchgit, fetchurl, luaOlder }:
      buildLuarocksPackage {
        pname = "etlua";
        version = "1.3.0-1";
        knownRockspec = (fetchurl {
          url = "mirror://luarocks/etlua-1.3.0-1.rockspec";
          sha256 = "1g98ibp7n2p4js39din2balncjnxxdbaq6msw92z072s2cccx9cf";
        }).outPath;
        src = fetchgit (removeAttrs
          (builtins.fromJSON ''{
  "url": "https://github.com/leafo/etlua.git",
  "rev": "8dda2e5aeb4413446172a562a9a374b700054836",
  "date": "2019-08-02T18:07:22-07:00",
  "path": "/nix/store/kk7sib6lwra0wyf6yjc8shkny7b5qnm7-etlua",
  "hash": "sha256-L16tGoKHYD1A1v612FvsbIs5OTPxd8h7Gh12qv/eR1s=",
  "fetchLFS": false,
  "fetchSubmodules": true,
  "deepClone": false,
  "leaveDotGit": false
}
 '') [ "date" "path" "sha256" ]);

        disabled = (luaOlder "5.1");
        propagatedBuildInputs = [ lua ];

        meta = {
          homepage = "https://github.com/leafo/etlua";
          description = "Embedded templates for Lua";
          license.fullName = "MIT";
        };
      })
    { };

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
    homepage = "git://github.com/leafo/lapis-console.git";
    description = "An interactive web based console for Lapis";
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
});

lapis-exceptions = callPackage(
{ buildLuarocksPackage, fetchgit, fetchurl, lapis, lua, tableshape }:
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
    homepage = "git://github.com/leafo/lapis-exceptions.git";
    description = "Track Lapis exceptions to database and email when they happen";
    license.fullName = "MIT";
  };
});

cloud_storage = callPackage ({ buildLuarocksPackage, date, fetchgit, fetchurl, lua, lua-cjson, luaOlder, luaexpat, luaossl, luasocket, mimetypes }:
buildLuarocksPackage {
  pname = "cloud_storage";
  version = "1.3.0-1";
  knownRockspec = (fetchurl {
    url    = "mirror://luarocks/cloud_storage-1.3.0-1.rockspec";
    sha256 = "0fhr4f4m9smwv4z2pq6l0gwf4rfna21fi4z7qb80hwvl5z8j1yvh";
  }).outPath;
  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "https://github.com/leafo/cloud_storage.git",
  "rev": "1d527c2988f62cd667ea9e302d9f797a73c40d61",
  "date": "2022-07-08T17:06:08-07:00",
  "path": "/nix/store/12p3zz1lbasxs6bxkz3dzar7bhshq0w8-cloud_storage",
  "sha256": "0a8j8f9nbhygsidlybgl46rck388r2fq4sdyidsrfpd4ydrcbc1r",
  "hash": "sha256-ObDFcvOkXZd1i75pgp3ICI3JsiH0LU9b1M/DZZNDEik=",
  "fetchLFS": false,
  "fetchSubmodules": true,
  "deepClone": false,
  "leaveDotGit": false
}
 '') ["date" "path" "sha256"]) ;

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ date lua lua-cjson luaexpat luaossl luasocket mimetypes ];

  meta = {
    homepage = "git://github.com/leafo/cloud_storage.git";
    description = "Access Google Cloud Storage from Lua";
    license.fullName = "MIT";
  };
}) {};

# mimetypes = 


}
/* GENERATED - do not edit this file */
