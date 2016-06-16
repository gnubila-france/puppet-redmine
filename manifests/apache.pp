# == Class: redmine::apache
#
# Configure an apache VHost for redmine.
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
#  include '::redmine::apache'
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
class redmine::apache {

  include ::redmine
  include ::apache

  $user = $redmine::user
  $group = $redmine::group
  $install_dir = $redmine::install_dir
  $redmine_home = "${redmine::install_dir}"

  # where is $template_passenger being used ???
  #$template_passenger = $redmine::apache::template_passenger

  if $::redmine::ssl {
    include ::apache::mod::ssl

    file { $::redmine::ssl_cert:
      ensure  => 'file',
      owner   => $::apache::user,
      group   => $::apache::group,
      mode    => '0640',
      source  => $::redmine::ssl_cert_src,
      notify  => Class['::apache::service'],
      require => [
        File[$::redmine::ssl_cert_key],
        File[$::redmine::ssl_ca_cert],
      ]
    }
    file { $::redmine::ssl_cert_key:
      ensure => 'file',
      owner  => $::apache::user,
      group  => $::apache::group,
      mode   => '0400',
      source => $::redmine::ssl_cert_key_src,
      notify => Class['::apache::service'],
    }
    if ! defined(File[$::redmine::ssl_ca_cert]) {
      file { $::redmine::ssl_ca_cert:
        ensure => 'file',
        owner  => $::apache::user,
        group  => $::apache::group,
        mode   => '0640',
        source => $::redmine::ssl_ca_cert_src,
        notify => Class['::apache::service'],
      }
    }
    if $::redmine::ssl_ca_cert_chain != undef and
      ! defined(File[$::redmine::ssl_ca_cert_chain]) {
      file { $::redmine::ssl_ca_cert_chain:
        ensure => 'file',
        owner  => $::apache::user,
        group  => $::apache::group,
        mode   => '0640',
        source => $::redmine::ssl_ca_cert_chain_src,
        notify => Class['::apache::service'],
      }
    }
  }

  $path = [
    "${::redmine::user_home}/.rbenv/shims",
    "${::redmine::user_home}/.rbenv/bin",
    '/bin', '/usr/bin', '/usr/sbin'
  ]
  exec { "gem install passenger --version ${::redmine::passenger_version} --no-ri --no-rdoc":
    user   => $user,
    cwd    => $redmine_home,
    path   => $path,
    unless => "gem list passenger | grep -q '^passenger.*${::redmine::passenger_version}'",
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
    ensure => 'file',
    owner  => $user,
    group  => $user,
    mode   => '0644',
  }

  $rack_location = "${redmine_home}/public/"
  $custom_fragment = "LoadModule passenger_module ${::redmine::user_home}/.rbenv/versions/${::redmine::ruby_version}/lib/ruby/gems/1.9.1/gems/passenger-${::redmine::passenger_version}/buildout/apache2/mod_passenger.so
PassengerRoot ${::redmine::user_home}/.rbenv/versions/${::redmine::ruby_version}/lib/ruby/gems/1.9.1/gems/passenger-${::redmine::passenger_version}
PassengerDefaultRuby ${::redmine::user_home}/.rbenv/versions/${::redmine::ruby_version}/bin/ruby
RailsBaseURI /
# you probably want to tune these settings
PassengerHighPerformance on
PassengerMaxPoolSize 12
PassengerPoolIdleTime 1500
# PassengerMaxRequests 1000
PassengerStatThrottleRate 120"
  apache::vhost { $::redmine::server_name:
    port                 => '443',
    serveraliases        => $::redmine::serveraliases,
    docroot              => $rack_location,
    directories          => [
      {
        path     => $rack_location,
        provider => 'directory',
        order    => 'allow,deny',
        allow    => 'from all',
        options  => ['None'],
        override => ['None'],
      },
    ],
    custom_fragment      => $custom_fragment,
    ssl                  => true,
    ssl_cert             => $::redmine::ssl_cert,
    ssl_key              => $::redmine::ssl_cert_key,
    ssl_chain            => $::redmine::ssl_ca_cert_chain,
    ssl_ca               => $::redmine::ssl_ca_cert,
    ssl_protocol         => $::redmine::ssl_protocol,
    ssl_cipher           => $::redmine::ssl_cipher_suite,
    ssl_honorcipherorder => 'On',
    require              => File['redmine_link']
  }
}

# vim: set et sw=2:
