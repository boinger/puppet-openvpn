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
        require => Exec["untar ${tarball} into ${configdir}/${tarbasename}"];
    }

  } else { $tarbasename = $name }

  exec {
    "md5sum ${name} OpenVPN config bundles":
      cwd     => $dropfolder,
      command => "/usr/bin/md5sum ${tarball} > ${tarball}.md5sum",
      unless  => "/bin/bash -c \"[ -f ${tarball} ] && [ \"$(md5sum ${tarball})\" == \"$(cat ${tarball}.md5sum)\" ]\"",
      notify  => Exec["untar ${tarball} into ${configdir}/${tarbasename}"],
      require => File[$dropfolder];

    "untar ${tarball} into /etc/openvpn/${tarbasename}":
      cwd     => $configdir,
      command => "/bin/tar xfv ${dropfolder}/${tarball}",
      creates => "/etc/openvpn/$tarbasename",
      require => File["/etc/openvpn/${name}"];
  }

  if ($serviceprovider == "daemontools" ) {

    $user = openvpn
    $loguser = openvpn

    daemontools::setup{
      "openvpn/${name}":
        user    => $user,
        loguser => $loguser,
        run     => template("${module_name}/service/run.erb"),
        logrun  => template("${module_name}/service/log/run.erb"),
        notify  => Daemontools::Service["openvpn-${name}"];
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
