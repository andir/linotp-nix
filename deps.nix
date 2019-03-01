{ pkgs, fetchFromGitHub, lib }:
self: super:
let
  inherit (super) buildPythonPackage fetchPypi;
in {
  # sqlalchemy = (super.sqlalchemy.overrideAttrs (old: {
  #     src = fetchPypi {
  #       pname = "SQLAlchemy";
  #       version = "1.0.15";
  #       sha256 = "0nl4w2wc117mqv51n9h0psv0cc6cqnbd28pdi5d7j4c20v7mqvsq";
  #     };
  # }));

  Pylons = buildPythonPackage rec {
    pname = "Pylons";
    version = "1.0.3";
    src = fetchPypi {
      inherit pname version;
      sha256 = "1a0dywpq943bdxpkjvszsr9gxzbcj2sy7mcx960adgpirq0i8aa9";
    };
    propagatedBuildInputs = with self; [ PasteScript WebError Mako ] ++ (with super; [ markupsafe tempita beaker routes FormEncode decorator simplejson webhelpers ]);
    checkInputs = with super; [ genshi jinja2 ];
    meta.license = with lib.licenses; [ bsd3 ];
  };
  PasteScript = buildPythonPackage rec {
    pname = "PasteScript";
    version = "2.0.2";
    src = fetchPypi {
      inherit pname version;
      sha256 = "1h3nnhn45kf4pbcv669ik4faw04j58k8vbj1hwrc532k0nc28gy0";
    };
    propagatedBuildInputs = with self; [ Paste PasteDeploy ] ++ (with super; [ six ]);
    checkInputs = with super; [ nose unittest2 ];
    doCheck = false; # fails with some make_test_application ArgumentError (1 expected, 0 provided)
  };
  Paste = buildPythonPackage rec {
    pname = "Paste";
    version = "3.0.4";
    src = fetchPypi {
      inherit pname version;
      sha256 = "01w26w9jyfkh0mfydhfz3dwy3pj3fw7mzvj0lna3vs8hyx1hwl0n";
    };
    propagatedBuildInputs = with super; [six];
    preCheck = ''
      # remove tests that fail due to missing network connectivity
      rm tests/test_proxy.py
      patchShebangs tests
    '';
    checkInputs = with super; [ pytest pytestrunner ];
  };
  WebError = buildPythonPackage rec {
    pname = "WebError";
    version = "0.13.1";
    src = fetchPypi {
      inherit pname version;
      sha256 = "0r4qvnf2r92gfnpa1kwygh4j2x6j3axg2i4an6hyxwg2gpaqp7y1";
    };
    propagatedBuildInputs = with self; [ Paste ] ++ (with super; [ pygments tempita webtest webob]);
  };
  Mako = buildPythonPackage rec {
    pname = "Mako";
    version = "1.0.7";
    src = fetchPypi {
      inherit pname version;
      sha256 = "1bi5gnr8r8dva06qpyx4kgjc6spm2k1y908183nbbaylggjzs0jf";
    };
    propagatedBuildInputs = with self; [ ] ++ (with super; [ markupsafe mock ]);
    checkInputs = with super; [ pytest ];
  };
  pyrad = buildPythonPackage rec {
    pname = "pyrad";
    version = "2.1";
    # pypi is missing the test data
    src = fetchFromGitHub {
      owner = "wichert";
      repo = "pyrad";
      rev = "${version}";
      sha256 = "14i309r0z3g0x9p4mmwyiddl3blgqznaa6h0254g7xf8wph1fffk";
    };
    propagatedBuildInputs = with super; [ six netaddr ];
    checkInputs = with super; [ nose ];
  };
  pysodium = buildPythonPackage rec {
    pname = "pysodium";
    version = "0.7.0-0";
    src = fetchPypi {
      inherit pname version;
      sha256 = "0xdld9vfr2hlf0nxxw4d2rn6wizikwydvp2964nyv6h9pffrdw40";
    };
    buildInputs = with pkgs; [ libsodium ];
    postPatch = ''
      sed -e 's,sodium = ctypes.cdll.LoadLibrary(.*$,sodium = ctypes.cdll.LoadLibrary("${pkgs.libsodium}/lib/libsodium.so"),' -i pysodium/__init__.py
    '';
  };
}
