{ stdenv
, runCommand
, nixos-artwork
, glib
, gtk3
, gsettings-desktop-schemas
, extraGSettingsOverrides ? ""
, extraGSettingsOverridePackages ? []
, mint-artwork

, muffin
, nemo
, xapps
, cinnamon-desktop
, cinnamon-session
, cinnamon-settings-daemon
, cinnamon-common
}:

let

  gsettingsOverridePackages = [
    # from
    mint-artwork

    # on
    muffin
    nemo
    xapps
    cinnamon-desktop
    cinnamon-session
    cinnamon-settings-daemon
    cinnamon-common
    gtk3
  ] ++ extraGSettingsOverridePackages;

in

with stdenv.lib;

# TODO: Having https://github.com/NixOS/nixpkgs/issues/54150 would supersede this
runCommand "cinnamon-gsettings-overrides" {}
  ''
     schema_dir=$out/share/gsettings-schemas/nixos-gsettings-overrides/glib-2.0/schemas

     mkdir -p $schema_dir

     ${concatMapStrings (pkg: "cp -rf ${glib.getSchemaPath pkg}/*.xml ${glib.getSchemaPath pkg}/*.gschema.override $schema_dir\n") gsettingsOverridePackages}

     chmod -R a+w $out/share/gsettings-schemas/nixos-gsettings-overrides

     cat - > $schema_dir/nixos-defaults.gschema.override <<- EOF
     ${extraGSettingsOverrides}
     EOF

     ${glib.dev}/bin/glib-compile-schemas $schema_dir
  ''
