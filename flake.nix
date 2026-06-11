{
  description = "Flutter";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          android_sdk.accept_license = true;
          allowUnfree = true;
        };
      };

      androidComposition = pkgs.androidenv.composeAndroidPackages {
        buildToolsVersions = ["34.0.0" "35.0.0"];
        platformVersions = [36 35 34 33 31];
        includeNDK = true;
        ndkVersions = ["27.0.12077973"];
        includeCmake = true;
        cmakeVersions = ["3.22.1"];
      };

      androidSdk = androidComposition.androidsdk;
      sdkPath = "${androidSdk}/libexec/android-sdk";
    in {
      devShell = pkgs.mkShell {
        ANDROID_SDK_ROOT = sdkPath;
        ANDROID_HOME = sdkPath;

        buildInputs = with pkgs; [
          gst_all_1.gstreamer
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good
          orc
          gtk3
        ];

        nativeBuildInputs = with pkgs; [
          flutter
          androidSdk
          jdk
          ninja
          unzip
          firebase-tools
          go
          google-cloud-sdk
          pkg-config
          gst_all_1.gstreamer.dev
          gst_all_1.gst-plugins-base.dev
          orc.dev
          libunwind.dev
        ];

        shellHook = ''
          export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdkPath}/build-tools/35.0.0/aapt2"
          git config core.hooksPath scripts/git-hooks
          export GSETTINGS_SCHEMA_DIR="${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.pname}-${pkgs.gtk3.version}/glib-2.0/schemas"
        '';
      };
    });
}
