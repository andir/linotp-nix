import <nixpkgs/nixos/tests/make-test.nix> ({
  nodes = {
    linotp = { pkgs, ... }: {
      imports = [ ./module.nix ];
      services.linotp.enable = true;
    };
  };
  testScript = ''
    startAll;
    $linotp->waitForUnit("multi-user.target");
    $linotp->waitForOpenPort(5000);
    $linotp->succeed("curl 127.0.0.1:5000");
  '';
})
