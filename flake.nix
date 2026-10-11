{
  description = "Declarative StarIntel relation artifacts and canonical verification";
  inputs.star-lang.url = "github:lost-rob0t/star-lang/bfba04a15f43215cd323e1dde2d98a7343abb3ea";
  inputs.nixpkgs.follows = "star-lang/nixpkgs";
  outputs = { self, nixpkgs, star-lang }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      compiler = star-lang.packages.${system}.star-lang;
      artifacts = pkgs.stdenvNoCC.mkDerivation {
        pname = "star-relations";
        version = "1.0.0";
        src = self;
        dontBuild = true;
        installPhase = ''
          mkdir -p "$out/share/star-relations"
          cp -R spec lock README.org LICENSE "$out/share/star-relations/"
        '';
      };
      verify = pkgs.writeShellApplication {
        name = "verify-star-relations";
        runtimeInputs = [ pkgs.python3 pkgs.coreutils ];
        text = ''
          export STAR_RELATIONS_ROOT=${artifacts}/share/star-relations
          export STAR_LANG=${compiler}/bin/starlang
          exec ${pkgs.bash}/bin/bash ${./scripts/verify-local.sh}
        '';
      };
      check = pkgs.runCommand "star-relations-verified" { } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME" "$TMPDIR/outside-source"
        cd "$TMPDIR/outside-source"
        ${verify}/bin/verify-star-relations
        touch "$out"
      '';
    in {
      packages.${system} = { default = artifacts; star-relations = artifacts; inherit verify; };
      apps.${system} = {
        default = self.apps.${system}.verify;
        verify = { type = "app"; program = "${verify}/bin/verify-star-relations"; };
      };
      checks.${system}.default = check;
    };
}
