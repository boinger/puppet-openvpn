# == Define: openvpn::service
#
# This class maintains the openvpn service
#
#
# === Examples
#
# This class should probably not be directly invoked
#
# === Authors
#
# * Raffael Schmid <mailto:raffael@yux.ch>
# * John Kinsella <mailto:jlkinsel@gmail.com>
# * Justin Lambert <mailto:jlambert@letsevenup.com>
# * Jeff Vier <mailto:jeff@jeffvier.com>
#
# === License
#
# Copyright 2013 Raffael Schmid, <raffael@yux.ch>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
define openvpn::service (
  $serviceprovider = 'daemontools'
){
  if ($serviceprovider == "daemontools" ) {
    daemontools::setup {
      "openvpn":
        user    => $openvpn::server::user,
        loguser => $openvpn::server::user,
        run     => template("${module_name}/service/run.erb"),
        logrun  => template("${module_name}/service/log/run.erb"),
        notify  => Daemontools::Service["openvpn-server"],
        require => File["/etc/openvpn/${name}"];
    }

    daemontools::service {
    "openvpn-server":
      source  => "/etc/openvpn",
      require => Daemontools::Setup["openvpn"];
    }
  } else {
    service {
      'openvpn':
        ensure     => running,
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
        require    => Class['openvpn::server'];
    }
  }
}
