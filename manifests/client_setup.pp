# == Define: openvpn::client_setup
#
# This define setups up client configs based on a tarball from the openvpn::client class
#
# === Parameters
#
# [*name*]
#   String.  Name of the openvpn config to be set up.
#
#   Note: do not include the '.tar.gz'
#
#   Required
#
# [*dropfolder*]
#   String.  Location to find the tarball'd config bundle
#
# [*tarball*]
#   String.  Name of the tarball.  Defaults to ${name}.tar.gz
#
# [*serviceprovider*]
#   String.  What should set this service up?
#
#   Daemontools only, right now.
#
# === Examples
#
#   openvpn::client_setup {
#     'uat_nagios':
#       dropfolder => /var/tmp/dump
#    }
#
# * Removal:
#     Manual process right now, todo for the future
#
#
# === Authors
#
# * Jeff Vier <mailto:jeff@jeffvier.com>
#
# === License
#
# Copyright 2013 Jeff Vier <jeff@jeffvier.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
define openvpn::client_setup(
  $dropfolder = '/etc/openvpn/tarballs',
  $tarball = "${name}.tar.gz",
  $serviceprovider = 'daemontools'
) {

  $user = openvpn
  $loguser = openvpn

  if ! defined (File[$dropfolder]) {
    file {
      $dropfolder:
        ensure  => directory;
    }
  }

  if ("${name}.tar.gz" != "$tarball") {
    $tarbasename = regsubst($tarball,'^(.*)\.tar\.gz', '\1', 'I')

    file {
      "/etc/openvpn/${name}":
        ensure  => "/etc/openvpn/$tarbasename",
        require => Exec["untar ${tarball} into /etc/openvpn/${tarbasename}"];

      "/etc/openvpn/${tarbasename}":
        mode    => 0755,
        owner   => $user,
        require => Exec["untar ${tarball} into /etc/openvpn/${tarbasename}"];
    }

  } else {
    $tarbasename = $name

    file {
      "/etc/openvpn/${name}":
        mode    => 0755,
        owner   => $user,
        require => Exec["untar ${tarball} into /etc/openvpn/${tarbasename}"];
    }
  }

  file {
    "/etc/openvpn/${name}/keys":
      owner   => $user,
      recurse => true,
      mode    => 0644
      require => File["/etc/openvpn/${name}"];

    "/etc/openvpn/${name}/keys/${name}.key":
      owner   => $user,
      mode    => 0600
      require => File["/etc/openvpn/${name}"];

    "/etc/openvpn/${name}/${name}.conf":
      owner   => $user,
      require => File["/etc/openvpn/${name}"];
  }

  exec {
    "untar ${tarball} into /etc/openvpn/${tarbasename}":
      cwd         => "/etc/openvpn",
      command     => "/bin/tar xfv ${dropfolder}/${tarball}",
      onlyif      => "/usr/bin/test ! -f /etc/openvpn/${name}/${tarball}.md5sum || /usr/bin/test \"$(cat /etc/openvpn/${name}/${tarball}.md5sum)\" != \"$(cat ${dropfolder}/${tarball}.md5sum)\"",
      notify      => Exec["copy ${tarball}.md5sum into conf dir"],
      require     => Package['openvpn'];

    "copy ${tarball}.md5sum into conf dir":
      cwd         => $dropfolder,
      command     => "/bin/cp ${tarball}.md5sum /etc/openvpn/${name}/",
      refreshonly => true,
      require     => File[$dropfolder];
  }

  if ($serviceprovider == "daemontools" ) {

    daemontools::setup {
      "openvpn/${name}":
        user    => $user,
        loguser => $loguser,
        run     => template("${module_name}/service/run.erb"),
        logrun  => template("${module_name}/service/log/run.erb"),
        notify  => Daemontools::Service["openvpn-${name}"],
        require => File["/etc/openvpn/${name}"];
    }

    daemontools::service {
    "openvpn-${name}":
      source  => "/etc/openvpn/${name}",
      require => Daemontools::Setup["openvpn/${name}"];
    }
  }
  else {
    notify { "We only have configs for daemontools. Sorry. You'll have to hack in whatever you expected serviceprovider => {serviceprovider} to do.": }
  }

}
