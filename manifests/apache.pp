# == Class: puppet-redmine::apache
#
# Full description of class puppet-redmine::apache here
#
# === Parameters
#
# [*user*]
#   Name of the user for running redmine passenger.
#   Default: redmine
#
# [*group*]
#   Name of the group for running redmine passenger.
#   Default: redmine
#
# [*redmine_home*]
#   Home directory for the redmine installation.
#   Default: /home/redmine/redmine
#
# [*template_passenger*]
#   Name of the template used for redmine passenger configuration.
#   Default: redmine/passenger.erb
#
# === Examples
#
#  include '::puppet-redmine::apache'
#
# Configuration is done using Hiera.
#
# === Authors
#
# Baptiste Grenier <bgrenier@gnubila.fr>
#
# === Copyright
#
# Copyright 2015 gnúbila
#
class redmine::apache (
  $user = $redmine::owner,
  $group = $user,
  $redmine_home = "${redmine::install_dir}/redmine",
  $template_passenger = params_lookup( 'template_passenger' ),
) inherits redmine::params {
  include ::redmine
  include ::apache

  if $::redmine::ssl {
    include apache::ssl
    # Required for redirection to https
    if ! defined(Apache::Module['rewrite']) {
     apache::module { 'rewrite':
       ensure => 'present',
     }
    }
    # XXX on debian Listen 443 is set in ports.conf, but NameVirtualHost is not
    if ! defined(File_line['namevirtualhost-443']) {
      file_line { 'namevirtualhost-443':
        ensure => 'present',
        path   => '/etc/apache2/ports.conf',
        line   => 'NameVirtualHost *:443',
        match  => '^\s*NameVirtualHost\s*\*:443',
        notify => Service['apache']
      }
    }
    file { $::redmine::ssl_cert:
      ensure  => 'present',
      owner   => 'www-data',
      group   => 'www-data',
      mode    => '0640',
      source  => $::redmine::ssl_cert_src,
      notify  => Service['apache'],
      require => [
        File[$::redmine::ssl_cert_key],
        File[$::redmine::ssl_ca_cert],
      ]
    }
    file { $::redmine::ssl_cert_key:
      ensure => 'present',
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0400',
      source => $::redmine::ssl_cert_key_src,
      notify => Service['apache'],
    }
    if ! defined(File[$::redmine::ssl_ca_cert]) {
      file { $::redmine::ssl_ca_cert:
        ensure  => 'present',
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0640',
        source  => $::redmine::ssl_ca_cert_src,
        notify  => Service['apache'],
      }
    }
    if $::redmine::ssl_ca_cert_chain != undef and
      ! defined(File[$::redmine::ssl_ca_cert_chain]) {
      file { $::redmine::ssl_ca_cert_chain:
        ensure => 'present',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0640',
        source => $::redmine::ssl_ca_cert_chain_src,
        notify => Service['apache'],
      }
    }
  }

  $path = [
    "${redmine::install_dir}/.rbenv/shims",
    "${redmine::install_dir}/.rbenv/bin",
    '/bin', '/usr/bin', '/usr/sbin'
  ]
  exec { "gem install passenger --version ${passenger_version} --no-ri --no-rdoc":
    user   => $user,
    cwd    => $redmine_home,
    path   => $path,
    unless => "gem list passenger | grep -q '^passenger.*${passenger_version}'",
    notify => Exec['passenger-install-apache2-module -a'],
  }
  exec { 'passenger-install-apache2-module -a':
    user        => $user,
    cwd         => $redmine_home,
    path        => $path,
    refreshonly => true,
  }

  file { [ "${redmine_home}/public", "${redmine_home}/tmp" ]:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
  }

  file { "${redmine_home}/config.ru":
    ensure  => 'present',
    owner   => $user,
    group   => $user,
    mode    => '0644',
  }

  $vhost_priority = 10
  $rack_location = "${redmine_home}/public/"
  apache::vhost { $::redmine::server_name:
    server_name   => $::redmine::server_name,
    ip_addr       => $::redmine::ip_addr,
    serveraliases => $::redmine::serveraliases,
    priority      => $vhost_priority,
    docroot       => $rack_location,
    ssl           => $redmine::ssl,
    template      => $redmine::template_passenger,
    require       => File['redmine_link']
  }
}

# vim: set et sw=2:
