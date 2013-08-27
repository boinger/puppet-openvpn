# == Define: openvpn::server
#
# This define creates the openvpn server instance and ssl certificates
#
#
# === Parameters
#
# [*country*]
#   String.  Country to be used for the SSL certificate
#
# [*province*]
#   String.  Province to be used for the SSL certificate
#
# [*city*]
#   String.  City to be used for the SSL certificate
#
# [*organization*]
#   String.  Organization to be used for the SSL certificate
#
# [*email*]
#   String.  Email address to be used for the SSL certificate
#
# [*compression*]
#   String.  Which compression algorithim to use
#   Default: comp-lzo
#   Options: comp-lzo or '' (disable compression)
#
# [*dev*]
#   String.  Device method
#   Default: tun
#   Options: tun (routed connections), tap (bridged connections)
#
# [*user*]
#   String.  Group to drop privileges to after startup
#   Default: nobody
#
# [*group*]
#   String.  User to drop privileges to after startup
#   Default: depends on your $::osfamily
#
# [*ipp*]
#   Boolean.  Persist ifconfig information to a file to retain client IP
#     addresses between sessions
#   Default: false
#
# [*local*]
#   String.  Interface for openvpn to bind to.
#   Default: $::ipaddress_eth0
#   Options: An IP address or '' to bind to all ip addresses
#
# [*logfile*]
#   String.  Logfile for this openvpn server
#   Default: false
#   Options: false (syslog) or log file name
#
# [*port*]
#   Integer.  The port the openvpn server service is running on
#   Default: 1194
#
# [*proto*]
#   String.  What IP protocol is being used.
#   Default: udp
#   Options: tcp or udp
#
# [*status_log*]
#   String.  Logfile for periodic dumps of the vpn service status
#   Default: "${name}/openvpn-status.log"
#
# [*server*]
#   String.  Network to assign client addresses out of
#   Default: None.  Required in tun mode, not in tap mode
#
# [*tls_server*]
#   Boolean. Enable TLS and assume server role during TLS handshake. Note that OpenVPN is
#     designed as a peer-to-peer application. The designation of client or server is only
#     for the purpose of negotiating the TLS control channel. 
# Default: true
#
# [*keepalive*]
#   String. The keepalive directive causes ping-like messages to be sent back and forth over
#     the link so that each side knows when the other side has gone down.
#     Ping every 10 seconds, assume that remote peer is down if no ping received during
#     a 120 second time period.
# Default: 10 120
#
# [*persist_key*]
#   Boolean.  Try to retain access to resources that may be unavailable
#     because of privilege downgrades
#   Default: true
#
# [*persist_tun*]
#   Boolean.  Try to retain access to resources that may be unavailable
#     because of privilege downgrades
#   Default: true
#
# [*mute*]
#   Integer.  Set log mute level
#   Default: 20
#
# [*verb*]
#   Integer.  Level of logging verbosity
#   Default: 3 (required field)
#
# [*push*]
#   Array.  Options to push out to the client.  This can include routes, DNS
#     servers, DNS search domains, and many other options.
#   Default: []
#
#
# === Examples
#
#   openvpn::client {
#     'my_user':
#       server      => 'contractors',
#       remote_host => 'vpn.mycompany.com'
#    }
#
# * Removal:
#     Manual process right now, todo for the future
#
#
# === Authors
#
# * Raffael Schmid <mailto:raffael@yux.ch>
# * John Kinsella <mailto:jlkinsel@gmail.com>
# * Justin Lambert <mailto:jlambert@letsevenup.com>
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
define openvpn::server(
  $country,
  $province,
  $city,
  $organization,
  $email,
  $compression = 'comp-lzo',
  $dev = 'tun0',
  $user = 'nobody',
  $group = false,
  $ipp = false,
  $ip_pool = [],
  $local = $::ipaddress_eth0,
  $logfile = false,
  $port = '1194',
  $proto = 'udp',
  $status_log = "${name}/openvpn-status.log",
  $server = '',
  $tls_server = true,
  $keepalive = '10 120',
  $persist_key = true,
  $persist_tun = true,
  $verb = 3,
  $mute = 20,
  $push = []
) {

  include openvpn
  openvpn::service { $name: }

  Class['openvpn::install'] ->
  Openvpn::Server[$name]

  $group_to_set = $group ? {
    false   => $openvpn::params::group,
    default => $group
  }

  file {
    ["/etc/openvpn/${name}", "/etc/openvpn/${name}/client-configs", "/etc/openvpn/${name}/download-configs" ]:
      ensure  => directory;
  }

  exec {
    "copy easy-rsa to openvpn config folder ${name}":
      command => "/bin/cp -r ${openvpn::params::easyrsa_source} /etc/openvpn/${name}/easy-rsa",
      creates => "/etc/openvpn/${name}/easy-rsa",
      notify  => Exec["fix_easyrsa_file_permissions_${name}"],
      require => [ File["/etc/openvpn/${name}"], Package['easy-rsa']];

    "fix_easyrsa_file_permissions_${name}":
      refreshonly => true,
      command     => "/bin/chmod 755 /etc/openvpn/${name}/easy-rsa/*",
      require => [ File["/etc/openvpn/${name}"], Package['easy-rsa']];

    "generate dh param ${name}":
      command  => '. ./vars && ./clean-all && ./build-dh',
      cwd      => "/etc/openvpn/${name}/easy-rsa",
      creates  => "/etc/openvpn/${name}/easy-rsa/keys/dh1024.pem",
      provider => 'shell',
      require  => [ File["/etc/openvpn/${name}/easy-rsa/vars"], Package['easy-rsa']];

    "initca ${name}":
      command  => '. ./vars && ./pkitool --initca',
      cwd      => "/etc/openvpn/${name}/easy-rsa",
      creates  => "/etc/openvpn/${name}/easy-rsa/keys/ca.key",
      provider => 'shell',
      require  => [ Exec["generate dh param ${name}"],
                    File["/etc/openvpn/${name}/easy-rsa/openssl.cnf"],
                    Package['easy-rsa'],
                    ];

    "generate server cert ${name}":
      command  => '. ./vars && ./pkitool --server server',
      cwd      => "/etc/openvpn/${name}/easy-rsa",
      creates  => "/etc/openvpn/${name}/easy-rsa/keys/server.key",
      provider => 'shell',
      require  => Exec["initca ${name}"];
  }

  file {
    "/etc/openvpn/${name}/easy-rsa/vars":
      ensure  => present,
      content => template('openvpn/vars.erb'),
      require => Exec["copy easy-rsa to openvpn config folder ${name}"];

    "/etc/openvpn/${name}/easy-rsa/openssl.cnf":
      require => Exec["copy easy-rsa to openvpn config folder ${name}"];

    "/etc/openvpn/${name}/keys":
      ensure  => link,
      target  => "/etc/openvpn/${name}/easy-rsa/keys",
      require => Exec["copy easy-rsa to openvpn config folder ${name}"];

    "/etc/openvpn/${name}.conf":
      owner   => root,
      group   => root,
      mode    => '0444',
      content => template('openvpn/server.erb'),
      notify  => Openvpn::Service[$name];
  }

  if $openvpn::params::link_openssl_cnf == true {
    File["/etc/openvpn/${name}/easy-rsa/openssl.cnf"] {
      ensure => link,
      target => "/etc/openvpn/${name}/easy-rsa/openssl-1.0.0.cnf"
    }
  }

  if $::osfamily == 'Debian' {
    concat::fragment {
      "openvpn.default.autostart.${name}":
        content => "AUTOSTART=\"\$AUTOSTART ${name}\"\n",
        target  => '/etc/default/openvpn',
        order   => 10;
    }
  }
}
