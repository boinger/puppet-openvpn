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
  $tarball = "${name}.tar.gz"
) {


  file {
    $dropfolder:
      ensure  => directory;
  }

  exec {
    "md5sum ${name} OpenVPN config bundles":
      cwd     => $dropfolder,
      command => "/usr/bin/md5sum ${tarball} > ${tarball}.md5sum",
      unless  => "/bin/bash -c \"[ -f ${tarball} ] && [ \"$(md5sum ${tarball})\" == \"$(cat ${tarball}.md5sum)\" ]\"",
      require => File[$dropfolder];
  }

}
