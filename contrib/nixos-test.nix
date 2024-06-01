/*
Script to test luarocks.site

Look at https://blog.thalheim.io/2023/01/08/how-to-execute-nixos-tests-interactively-for-debugging/
for how to debug this test
*/
{
  luaEnv
  ,...
}:

let

  s3Login = "mylogin";
  s3Password = "mypassword";
  s3Region = "eu-central-1";

  postgresPassword = "postgresPassword";

in
{
  name = "luarocks-site-tests";

  # for faster dev cycles
  skipLint = true;

  # Or a set of machines:
  nodes =
    {

      # to be able to test
      # minio =
      #   { config, pkgs, ... }: {
      #     services.minio = {
      #       enable = true;
      #       # accessKey = s3Login;
      #       # secretKey = s3password;
      #       rootCredentialsFile = "/etc/minio/credentials";
      #     };

      #     # credentialsFile = pkgs.writeTextFile ''
      #     environment.etc."minio/credentials".text = ''
      #       MINIO_ROOT_USER=${s3Login}
      #       MINIO_ROOT_PASSWORD=${s3Password}
      #     '';

      #     networking.firewall.enable = false;
      #   };

      postgres =
        { config, pkgs, ... }: {

          networking.firewall.enable = false;

          networking.firewall.allowedTCPPorts = [
            # config.services.postgresql.config.dbport
            5432
          ];

          services.postgresql = {
            enable = true;
            enableTCPIP = true;

            # <user>
            initialScript = pkgs.writeText "init-sql-script" ''
              alter user postgres with password '${postgresPassword}';
            '';

            ensureDatabases = [ "core" ];
            # ensureUsers = [
            #   {
            #     name = "core-ws";
            #     ensureClauses = {
            #       superuser = true;
            #       createdb = true;
            #       createrole = true;
            #       "inherit" = true;
            #       login = true;
            #       replication = true;
            #       bypassrls = true;
            #     };
            #   }
            #   {
            #     name = "default-clauses";
            #   }
            # ];
          };

        };

      # redis =
      #   { config, pkgs, lib, ... }: {
      #     # services.redis.servers."".enable = true;
      #     services.redis.servers.test = {
      #       enable = true;
      #       openFirewall = true;
      #       # passwordFile = "./redis.txt";
      #       requirePass = "toto";
      #       settings = {
      #         # disable client authentification
      #         tls-auth-clients = "no";
      #       };
      #     };
      #   };


      server = { config, pkgs, lib, ... }: {
        virtualisation.sharedDirectories = {
          my-share = {
            source = "/home/teto/luarocks-site";
            target = "/mnt/luarocks-site";
          };
        };
          
          # virtualisation.qemu.options = [
          #   "-virtfs local,path=/home/teto/luarocks-site,security_model=none,mount_tag=testmount"
          # ];
          # virtualisation.fileSystems."/testmount" =
          #   { device = "testmount";
          #     fsType = "9p";
          #     options = [ "trans=virtio" "version=9p2000.L" ];
          #     neededForBoot = true;
          #   };

        environment.systemPackages = [
          luaEnv # to bring lapis in PATH

          # to check .status results
          pkgs.curl
          pkgs.jq
          # pkgs.luaPackages.lapis
          # pkgs.nginx
          pkgs.openresty
          # pkgs.sassc
          # pkgs.openresty
          # pkgs.discount # for
          # pkgs.nodePackages.coffee-script

        ];

        # TODO pass a special config ?
        environment.sessionVariables = {
          POSTGRESQL_CONNECTION = "user=postgres password= host=postgres dbname=core";
        };

        systemd.services.luarocks-site = let 
          # /var/lib/onlyoffice/documentserver/sdkjs/{slide/themes,common}/ /var/lib/onlyoffice/documentserver/{fonts,server/FileConverter/bin}/
          # jq moreutils config.services.postgresql.package 
            # # Allow members of the onlyoffice group to serve files under /var/lib/onlyoffice/documentserver/App_Data
            # chmod g+x /var/lib/onlyoffice/documentserver
            # cp /run/onlyoffice/config/default.json{,.orig}
          # could be pasted via copy_from_host
          onlyoffice-prestart = pkgs.writeShellScript "onlyoffice-prestart" ''
            PATH=$PATH:${lib.makeBinPath (with pkgs; [ ])}
            umask 077
            mkdir -p /run/luarocks-site/ 
            cp ${../nginx.conf} /run/luarocks-site/
            cp ${../app.moon} /run/luarocks-site/
            cp ${../config.moon} /run/luarocks-site/
            chmod u+w /run/luarocks-site

            '';

          execLapis = pkgs.writeShellScript "start-lapis" ''
            echo "CURRENT DIR: $PWD"
            ls -l
            ${luaEnv}/bin/lapis serve
            '';
          in

          {
          description = "luarocks-site";
          wantedBy = [ "multi-user.target" ];

          path = [
            # pkgs.nginx
            pkgs.openresty
          ];

          serviceConfig = {
            Environment = [
              "POSTGRESQL_CONNECTION='user=postgres password=${postgresPassword} host=postgres dbname=core'"
              # "AWS_REGION=${s3Region}"
            ];

            # TODO it should have access to nginx
            ExecStartPre = [ onlyoffice-prestart ];
            # WorkingDirectory = "${prl-tools}/bin";

            # 
            ExecStart = execLapis;
            RuntimeDirectory = "luarocks-site";
            ProtectHome = true;
            # https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Specifiers
            # WorkingDirectory = "%t/luarocks-site";
            WorkingDirectory = "/mnt/luarocks-site";

          };
        };

        networking.firewall.enable = false;
      };

    };

  # machine.wait_for_file("${redis.servers."".unixSocket}")
  # machine.wait_for_file("${redis.servers."test".unixSocket}")

  # look at simwork/core-webservice/test/integration/distributed/test.sh
  # for config
  testScript = { nodes, ... }:
    # let
    # inherit (nodes.machine.config.services) redis;
    # in
    # with subtest("All user permissions are set according to the ensureClauses attr"):
      # redis.wait_for_unit("redis-test", timeout=60)

      # minio.wait_for_unit("minio")
    ''
      start_all()


      postgres.wait_for_unit("postgresql")

      server.copy_from_host("nginx.conf", "/root/nginx.conf")
      server.copy_from_host("app.moon", "/root/app.moon")
      server.copy_from_host("config.moon", "/root/config.moon")
      server.execute("cp -r ${../.} /root/site")


      server.execute("ls -lR /root")

      # we would need an s3 equivalent to test further ?
      # we setup POSTGRESQL_CONNECTION to allow the workers to
      # server.send_monitor_command("hostfwd_add tcp::8081-:8082")
      server.start_job("luarocks-site")

      server.forward_port(8080, 8080)

      # server.execute("journalctl")
      server.wait_for_unit("luarocks-site")

    '';

}
