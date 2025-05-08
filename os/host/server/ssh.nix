{
  pkgs,
  config,
  lib,
  ...
}: {
  users.users."authorized_keys" = {
    isSystemUser = true;
    description = "fetches SSH authorized keys";
    shell = pkgs.dash;
    group = "authorized_keys";
  };
  users.groups."authorized_keys" = {};

  services = {
    openssh = {
      enable = true;
      settings = {
        Banner = builtins.toString (pkgs.writeText "banner" ''
          SSH username pattern:

            <username>.<identity-provider>

          Known identity providers:

            - codeberg.org
            - github.com
            - gitlab.com

          E.g., "nat" on GitHub would do:

            ssh nat.github@${config.networking.fqdn}

          Questions?
            - mailto:lorenz@leutgeb.xyz
            - https://signal.me/#eu/QktoJMdqAR38SnDfPEkHJ0oT3_RN1ylq-yhSyA_9mZh1gaYIOmVLYbMOkE02pbBF
        '');
        AuthorizedKeysCommandUser = "authorized_keys";
        AuthorizedKeysCommand =
          (lib.getExe (pkgs.writeShellApplication {
            name = "authorized_keys";
            text = builtins.readFile ./authorized_keys;
          }))
          + " %u";
      };

      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };

    sshguard.enable = true;
  };
}
