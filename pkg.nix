{ python27Packages, lib, fetchFromGitHub, openssl, tzdata, glibcLocales }:
let
  version = "2.10.1.2";
  sha256 = "0fk18blp0l3660knmh79kclymix2q3dwv3pmamrl3ik8y9phmb61";


in python27Packages.buildPythonApplication {
  pname = "linotp";
  inherit version;

  src = fetchFromGitHub {
    owner = "LinOTP";
    repo = "LinOTP";
    rev = "release/${version}";
    inherit sha256;
  };

  preBuild = ''
    cd linotpd/src
    patchShebangs .
  '';

  propagatedBuildInputs = with python27Packages; [
    Pylons # >=0.9.7
    sqlalchemy
    webob
    docutils # >= 0.4
    simplejson # >=2.0
    pycryptodomex # >=3.4
    pyrad # >=1.1
    netaddr
    qrcode # >= 2.4
    configobj # >=4.6.0
    httplib2
    requests
    pysodium # >=0.6.8
    ldap
    m2crypto
  ];

  patches = [
    ./getmultiple.patch
  ];

  buildInputs = with python27Packages; [ Babel ];

  # these are all undocumented
  checkInputs = with python27Packages; [ unittest2 openssl freezegun glibcLocales ];
  checkPhase = ''
    export LANG=en_US.UTF-8
    export TZ=Europe/Berlin
    export TZDIR=${tzdata}/share/zoneinfo
    $out/bin/linotp-create-enckey -f test.ini
    $out/bin/linotp-create-auditkeys -f test.ini
    paster serve test.ini &
    nosetests --with-pylons=test.ini -e test_addr_in_network -e test_ipaddr_value -e test_network_value linotp/tests/unit
  '';

  meta = with lib; {
    homepage = "https://linotp.org";
    license = with lib.licenses; [ agpl3 ];
  };
}
