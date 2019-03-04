import <nixpkgs/nixos/tests/make-test.nix> ({
  nodes = {
    linotp = { pkgs, config, ... }: let
      bootstrapScript = pkgs.writeScriptBin "bootstrap" ''
        #!${pkgs.stdenv.shell}
        exec ${(pkgs.python3.withPackages (p: [ p.requests ]))}/bin/python ${./ci.py} --linotp http://127.0.0.1:${toString config.services.linotp.port} "$@"
  '';
    in {
      imports = [ ./module.nix ];
      services.linotp.enable = true;

      environment.systemPackages = [
        bootstrapScript
      ];
    };
  };
  testScript = ''
    startAll;
    $linotp->waitForUnit("multi-user.target");
    $linotp->waitForOpenPort(5000);
    $linotp->succeed("curl 127.0.0.1:5000");
    $linotp->succeed("bootstrap");
    # TODO: test authentication
  '';
})
