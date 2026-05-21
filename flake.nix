{
  description = "yo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      eachSystem = flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          packages.default = pkgs.stdenvNoCC.mkDerivation {
            pname = "goodmorningd";
            version = "0.1.0";
            src = self;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            installPhase = ''
              runHook preInstall

              mkdir -p $out/share/goodmorningd $out/bin
              cp index.ts package.json tsconfig.json bun.lock $out/share/goodmorningd/

              makeWrapper ${pkgs.bun}/bin/bun $out/bin/goodmorningd \
                --add-flags "run $out/share/goodmorningd/index.ts"

              runHook postInstall
            '';
          };

          apps.default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/goodmorningd";
          };

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.bun
            ];
          };
        }
      );
    in
    eachSystem
    // {
      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.services.goodmorningd;
        in
        {
          options.services.goodmorningd = {
            enable = lib.mkEnableOption "goodmorningd";

            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
              defaultText = lib.literalExpression "goodmorningd.packages.\${pkgs.stdenv.hostPlatform.system}.default";
              description = "The goodmorningd package to run.";
            };

            port = lib.mkOption {
              type = lib.types.port;
              default = 42069;
              description = "TCP port for goodmorningd to listen on.";
            };

            user = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "phil";
              description = ''
                User to run the service as. Set this to the user that has Codex authenticated
              '';
            };

            group = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "users";
              description = "Optional group to run the service as.";
            };

            codexPackage = lib.mkOption {
              type = lib.types.nullOr lib.types.package;
              default = null;
              example = lib.literalExpression "pkgs.codex";
              description = ''
                Optional package that provides the codex executable. Leave this
                null if codex is supplied through environment.systemPackages,
                users.users.<name>.packages, or another PATH mechanism.
              '';
            };

            environment = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              example = {
                CODEX_HOME = "/home/phil/.codex";
              };
              description = "Extra environment variables for the service.";
            };
          };

          config = lib.mkIf cfg.enable {
            systemd.services.goodmorningd = {
              description = "Good morning Codex trigger daemon";
              wantedBy = [ "multi-user.target" ];
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];

              path = lib.optionals (cfg.codexPackage != null) [ cfg.codexPackage ];

              environment = cfg.environment // {
                PORT = toString cfg.port;
              };

              serviceConfig = {
                ExecStart = "${cfg.package}/bin/goodmorningd";
                Restart = "on-failure";
                RestartSec = "5s";
              }
              // lib.optionalAttrs (cfg.user != null) {
                User = cfg.user;
              }
              // lib.optionalAttrs (cfg.group != null) {
                Group = cfg.group;
              };
            };
          };
        };
    };
}
