{ pkgs, config, lib, ... }:
let
  inherit (import ./default.nix { inherit pkgs; }) linotp python27;

  cfg = config.services.linotp;
in
with lib;
{

  options.services.linotp = {
    enable = mkEnableOption "Enable LinOTP";
    user = mkOption {
      type = types.str;
      default = "linotp";
    };
    group = mkOption {
      type = types.str;
      default = "linotp";
    };

    port = mkOption {
      type = types.int;
      default = 5000;
    };
    debug = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Run application in debug mode.
      '';
    };

    profile = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable profiling.
      '';
    };

    smtp_server = mkOption {
      type = types.str;
      default = "localhost";
      description = ''
        SMTP server to use for reporiting issues.
      '';
    };

    error_email_from = mkOption {
      type = types.str;
      default = "linotp@localhost";
      description = ''
        Source email address for mails.
      '';
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/linotp";
      description = ''
        Path at which the state files should be stored.
      '';
    };
    linotpAudit = {
      type = mkOption {
        default = "linotp.lib.audit.SQLAudit";
        type = types.nullOr types.str;
        description = ''
          Audit implementation to be used.
        '';
      };
      file.filename = mkOption {
        type = types.str;
        default = "${cfg.stateDir}/audit.log";
      };
      sql.url = mkOption {
        type = types.str;
        default = cfg.sqlalchemy.url;
        description = ''
          SQL Url that will be used to store the audit log.
        '';
      };
      sql.table_prefix = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Prefix for the log database table names.
        '';
      };
      sql.error_on_truncation = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Raise an exception if data would be truncated if written to the database.
        '';
      };
      sql.highwatermark = mkOption {
        type = types.int;
        default = 10000;
      };
      sql.lowwatermark = mkOption {
        type = types.int;
        default = 5000;
      };
      key.private = mkOption {
        type = types.str;
        default = "${cfg.stateDir}/private.pem";
        description = ''
          Location of the private.pem.
        '';
      };
      key.public = mkOption {
        type = types.str;
        default = "${cfg.stateDir}/public.pem";
        description = ''
          Location of the public.pem.
        '';
      };
    };

    DefaultSyncWindow = mkOption {
      type = types.int;
      default = 1000;
    };
    DefaultOtpLen = mkOption {
      type = types.int;
      default = 6;
    };
    DefaultCountWindow = mkOption {
      type = types.int;
      default = 50;
    };

    DefaultMaxFailCount = mkOption {
      type = types.int;
      default = 15;
    };

    FailCounterIncOnFalsePin = mkOption {
      type = types.bool;
      default = true;
    };

    PrependPin = mkOption {
      type = types.bool;
      default = true;
    };

    DefaultResetFailCount = mkOption {
      type = types.bool;
      default = true;
    };

    splitAtSign = mkOption {
      type = types.bool;
      default = true;
    };

    Getotp = mkOption {
      type = types.bool;
      default = false;
    };

    linotpSecretFile = mkOption {
      type = types.str;
      default = "${cfg.stateDir}/encKey";
    };

    sqlalchemy = {
      pool_recycle = mkOption {
        type = types.int;
        default = 3600;
      };
      url = mkOption {
        type = types.str;
        default = "sqlite:///${cfg.stateDir}/database.sqlite";
      };
    };

  };

  config = mkIf cfg.enable {
    users = {
      users.${cfg.user}= {
        isSystemUser = true;
        home = cfg.stateDir;
        createHome = true;
      };
      groups.${cfg.group}.members = [ "${cfg.user}" ];
    };
    systemd.services.linotpd = let
      pythonEnv = python27.withPackages(ps: with python27.pkgs; [ (toPythonModule linotp) ]);
      linotpIni = pkgs.writeText "linotp.ini" ''
        [DEFAULT]
        debug = ${if cfg.debug then "true" else "false"}
        profile = ${if cfg.profile then "true" else "false"}
        smtp_server = ${cfg.smtp_server}
        error_email_from = ${cfg.error_email_from}

        # Audit Log
        ${lib.optionalString (cfg.linotpAudit.type != null) ''linotpAudit.type = ${cfg.linotpAudit.type}''}
        audit.file.filename = ${cfg.linotpAudit.file.filename}
        linotpAudit.sql.url = ${cfg.linotpAudit.sql.url}
        linotpAudit.key.private = ${cfg.linotpAudit.key.private}
        linotpAudit.key.public = ${cfg.linotpAudit.key.public}
        linotpAudit.sql.highwatermark = ${toString cfg.linotpAudit.sql.highwatermark}
        linotpAudit.sql.lowwatermark = ${toString cfg.linotpAudit.sql.lowwatermark}
        ${lib.optionalString (cfg.linotpAudit.sql.table_prefix != null) "linotpAudit.sql.table_prefix = ${cfg.linotpAudit.sql.table_prefix}"}
        ${lib.optionalString (cfg.linotpAudit.sql.error_on_truncation != null) "linotpAudit.sql.error_on_truncation = ${if cfg.linotpAudit.sql.error_on_truncation then "True" else "False"}"}

        # Default LinOTP Token configuration
        linotp.DefaultSyncWindow = ${toString cfg.DefaultSyncWindow}
        linotp.DefaultOtpLen = ${toString cfg.DefaultOtpLen}
        linotp.DefaultCountWindow = ${toString cfg.DefaultCountWindow}
        linotp.DefaultMaxFailCount = ${toString cfg.DefaultMaxFailCount}
        linotp.FailCounterIncOnFalsePin = ${if cfg.FailCounterIncOnFalsePin then "True" else "False"}
        linotp.PrependPin = ${if cfg.PrependPin then "True" else "False"}
        linotp.DefaultResetFailCount = ${if cfg.PrependPin then "True" else "False"}
        linotp.splitAtSign = ${if cfg.splitAtSign then "True" else "False"}

        linotpSecretFile = ${cfg.linotpSecretFile}

        # TODO: Radius

        [app:main]
        use = egg:LinOTP
        sqlalchemy.pool_recycle = ${toString cfg.sqlalchemy.pool_recycle}
        sqlalchemy.url = ${cfg.sqlalchemy.url}
        cache_dir = /tmp/

        [server:main]
        use = egg:Paste#http
        host = 127.0.0.1
        port = ${toString cfg.port}


        # WARNING: *THE LINE BELOW MUST BE UNCOMMENTED ON A PRODUCTION ENVIRONMENT*
        # Debug mode will enable the interactive debugging tool, allowing ANYONE to
        # execute malicious code after an exception is raised.
        set debug = ${if cfg.debug then "true" else "false"}

        [handler_hand02]
        class=FileHandler
        level=WARN
        # formatter=form02
        args=('python.log', 'w')


        # Logging configuration
        [loggers]
        keys = root, linotp, token, tokenclass, policy, util, config, lib_validate, lib_user, controller
        #keys = root, linotp
        #keys = root, sqlalchemy

        [handlers]
        keys = file

        [logger_sqlalchemy]
        level = WARN
        handlers = file
        qualname = sqlalchemy.engine
        # "level = INFO" logs SQL queries.
        # "level = DEBUG" logs SQL queries and results.
        # "level = WARN" logs neither.  (Recommended for production systems.)




        [formatters]
        keys = generic

        [logger_root]
        level = WARN
        handlers = file

        [logger_routes]
        level = WARN
        handlers = file
        qualname = routes.middleware
        # "level = DEBUG" logs the route matched and routing variables.

        [logger_controller]
        level = DEBUG
        handlers = file
        qualname = linotp.controllers

        [logger_linotp]
        level = INFO
        handlers = file
        qualname = linotp

        [logger_lib_user]
        level = INFO
        handlers = file
        qualname = linotp.lib.user

        [logger_lib_validate]
        level = DEBUG
        handlers = file
        qualname = linotp.lib.validate

        [logger_token]
        level = DEBUG
        handlers = file
        qualname = linotp.lib.token

        [logger_tokenclass]
        level = DEBUG
        handlers = file
        qualname = linotp.lib.tokenclass

        [logger_policy]
        level = INFO
        handlers = file
        qualname = linotp.lib.policy

        [logger_config]
        level = WARN
        handlers = file
        qualname = linotp.lib.config

        [logger_util]
        level = WARN
        handlers = file
        qualname = linotp.lib.util

        [logger_sqlalchemy]
        level = ERROR
        handlers = file
        qualname = sqlalchemy.engine
        # "level = INFO" logs SQL queries.
        # "level = DEBUG" logs SQL queries and results.
        # "level = WARN" logs neither.  (Recommended for production systems.)

        [handler_console]
        class = StreamHandler
        args = (sys.stderr,)
        level = WARN
        formatter = generic

        [handler_file]
        class = handlers.RotatingFileHandler
        # Make the logfiles 10 MB
        # and rotate 4  files
        args = ('test.log','a', 10000000, 4)
        level = DEBUG
        formatter = generic


        [formatter_generic]
        format = %(asctime)s %(levelname)-5.5s {%(thread)d} [%(name)s][%(funcName)s #%(lineno)d] %(message)s
        datefmt = %H:%M:%S
      '';
    in {
      description = "LinOTP paster service";
      wantedBy = [ "multi-user.target" ];
        serviceConfig = {
        PrivateTmp = true;
        User = cfg.user;
        Group = cfg.group;
        PermissionsStartOnly = true;
        WorkingDirectory = cfg.stateDir;
        ExecStart = "${pythonEnv}/bin/paster serve ${linotpIni}";
      };
      preStart = ''
        set -ex
        test -e "${cfg.linotpSecretFile}" || ${pkgs.coreutils}/bin/dd if=/dev/urandom of='${cfg.linotpSecretFile}' bs=1 count=96
        test -e "${cfg.linotpAudit.key.private}" || ${pkgs.openssl}/bin/openssl genrsa -out "${cfg.linotpAudit.key.private}" 4096
        test -e "${cfg.linotpAudit.key.public}" || ${pkgs.openssl}/bin/openssl rsa -in "${cfg.linotpAudit.key.private}" -pubout -out "${cfg.linotpAudit.key.public}"

        chown -R ${cfg.user}:${cfg.group} ${cfg.stateDir}
      '';
    };
  };
}
