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
    "${::redmine::user_home}/bin",
    '/bin', '/usr/bin', '/usr/sbin'
  ]

  $docroot = "${redmine::install_dir}/public/"

  apache::vhost { "port80.${::redmine::server_name}":
    servername           => "${::redmine::server_name}",
    port                 => '80',
    docroot              => '/var/www/redirect',
    redirect_status      => 'permanent',
    redirect_dest        => "https://${::redmine::server_name}/",
  }

  apache::vhost { "port443.${::redmine::server_name}":
    servername           => "${::redmine::server_name}",
    port                 => '443',
    serveraliases        => $::redmine::serveraliases,
    docroot              => $docroot,
    directories          => [
      {
        path     => $docroot,
        provider => 'directory',
        order    => 'allow,deny',
        allow    => 'from all',
        options  => ['Indexes','ExecCGI','FollowSymLinks'],
        override => ['All'],
      },
    ],
    #custom_fragment      => $custom_fragment,
    #ssl                  => true,
    ssl                  => $::redmine::ssl,
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
