{
  self,
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../mixin/caddy.nix
    ../../mixin/kmscon.nix
    ../../mixin/nix.nix
    ../../mixin/motd.nix
    ../../mixin/sops.nix
    ./root.nix
    ./tor.nix
    ./ssh.nix
    ./home.nix
  ];

  garnix.server = {
    enable = true;
    persistence = {
      enable = true;
      name = "1";
    };
  };

  #systemd.network.enable = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking = {
    hostName = "radicle";
    domain = "lorenz.leutgeb.xyz";

    firewall = {
      allowedTCPPorts = [
        22 # ssh
        443 # https
      ];
    };
  };

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Set your time zone.
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    coreutils-full
    dmidecode
    exfat
    libvirt
    lshw
    lsof
    nfs-utils
    utillinux
    which
    config.boot.kernelPackages.perf
  ];

  services = {
    tor = {
      enable = true;
      client.enable = true;
    };
    accounts-daemon.enable = true;
    cron.enable = true;
    #journald.extraConfig = "ReadKMsg=no";

    logind.extraConfig = ''
      RuntimeDirectorySize=24G
    '';

    #resolved.enable = true;

    caddy = {
      enable = true;
      email = "lorenz.leutgeb@posteo.eu";
      virtualHosts = {
        "https://${config.networking.fqdn}".extraConfig = "respond `${builtins.toJSON {
          rev = self.rev or self.dirtyRev;
          inherit (self) lastModified;
        }}`";
      };
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  security = {
    sudo.wheelNeedsPassword = false;
  };

  sops = {
    age.sshKeyPaths = map (x: x.path) config.services.openssh.hostKeys;
    secrets = {
      "ssh/key".sopsFile = ./sops/ssh.yaml;
    };
  };
}
