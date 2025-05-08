{
  config,
  inputs,
  self,
  pkgs,
  ...
}: {
  users.motdFile = "/etc/motd";
  environment.etc.motd.text = ''
    ██     ██  █████  ██████  ███    ██ ██ ███    ██  ██████
    ██     ██ ██   ██ ██   ██ ████   ██ ██ ████   ██ ██
    ██  █  ██ ███████ ██████  ██ ██  ██ ██ ██ ██  ██ ██   ███
    ██ ███ ██ ██   ██ ██   ██ ██  ██ ██ ██ ██  ██ ██ ██    ██
     ███ ███  ██   ██ ██   ██ ██   ████ ██ ██   ████  ██████

    Experimental. Data will be erased without further notice.

     Radicle  ${pkgs.radicle-node.version} ${pkgs.radicle-node.src.rev}
      NixOS   ${config.system.nixos.release} ${inputs.nixpkgs.rev}
        •     ${self.rev or self.dirtyRev}
  '';
}
