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
  include ::apache::mod::passenger

  if $::redmine::ssl {

    include ::apache::mod::ssl

    # it seems that there should be a better way to choose between 'content' and 'source' attributes.
    # any suggestions?
    if  $::redmine::ssl_cert_content != 'undef'  {
      file { $::redmine::ssl_cert:
        ensure  => 'file',
        owner   => $::apache::user,
        group   => $::apache::group,
        mode    => '0640',
        notify  => Class['::apache::service'],
        content => $::redmine::ssl_cert_content,
        require => [
          File[$::redmine::ssl_cert_key],
          File[$::redmine::ssl_ca_cert],
        ]
      }
    } else {
      file { $::redmine::ssl_cert:
        ensure  => 'file',
        owner   => $::apache::user,
        group   => $::apache::group,
        mode    => '0640',
        notify  => Class['::apache::service'],
        source  => $::redmine::ssl_cert_src,
        require => [
          File[$::redmine::ssl_cert_key],
          File[$::redmine::ssl_ca_cert],
        ]
      }
    }


    if  $::redmine::ssl_cert_key_content != 'undef'  {
      file { $::redmine::ssl_cert_key:
        ensure => 'file',
        owner  => $::apache::user,
        group  => $::apache::group,
        mode   => '0400',
        content => $::redmine::ssl_cert_key_content,
        notify => Class['::apache::service'],
      }
    } else {
      file { $::redmine::ssl_cert_key:
        ensure => 'file',
        owner  => $::apache::user,
        group  => $::apache::group,
        mode   => '0400',
        source => $::redmine::ssl_cert_key_src,
        notify => Class['::apache::service'],
      }
    }

    if ! defined(File[$::redmine::ssl_ca_cert]) {
      if  $::redmine::ssl_ca_cert_content != 'undef'  {
        file { $::redmine::ssl_ca_cert:
          ensure  => 'file',
          owner   => $::apache::user,
          group   => $::apache::group,
          mode    => '0640',
          content => $::redmine::ssl_ca_cert_content,
          notify  => Class['::apache::service'],
        }
      } else {
        file { $::redmine::ssl_ca_cert:
          ensure => 'file',
          owner  => $::apache::user,
          group  => $::apache::group,
          mode   => '0640',
          source => $::redmine::ssl_ca_cert_src,
          notify => Class['::apache::service'],
        }
      }
    }

    if $::redmine::ssl_ca_cert_chain != undef and
      ! defined(File[$::redmine::ssl_ca_cert_chain]) {

      if  $::redmine::ssl_ca_cert_content != 'undef'  {
        file { $::redmine::ssl_ca_cert_chain:
          ensure => 'file',
          owner  => $::apache::user,
          group  => $::apache::group,
          mode   => '0640',
          content => $::redmine::ssl_ca_cert_chain_content,
          notify => Class['::apache::service'],
        }
      } else {
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
  }

  $path = [
    "${::redmine::user_home}/bin",
    '/bin', '/usr/bin', '/usr/sbin'
  ]

  $docroot = "${redmine::install_dir}/public/"

  apache::vhost { "${::redmine::server_name}-redirect":
    servername           => "${::redmine::server_name}",
    port                 => '80',
    docroot              => '/var/www/redirect',
    docroot_owner        => "$::redmine::user",
    docroot_group        => "$::redmine::group",
    redirect_status      => 'permanent',
    redirect_dest        => "https://${::redmine::server_name}/",
  }

  apache::vhost { "${::redmine::server_name}-SSL":
    servername           => "${::redmine::server_name}",
    port                 => '443',
    serveraliases        => $::redmine::serveraliases,
    docroot              => $docroot,
    docroot_owner        => "$::redmine::user",
    docroot_group        => "$::redmine::group",
    directories          => [
      {
        path              => $docroot,
        provider          => 'directory',
        order             => 'allow,deny',
        allow             => 'from all',
        options           => ['Indexes','ExecCGI','FollowSymLinks'],
        override          => ['All'],
        passenger_enabled => 'on',
      },
    ],
    ssl                  => $::redmine::ssl,
    ssl_cert             => $::redmine::ssl_cert,
    ssl_key              => $::redmine::ssl_cert_key,
    #ssl_chain            => $::redmine::ssl_ca_cert_chain,
    #ssl_ca               => $::redmine::ssl_ca_cert,
    ssl_protocol         => $::redmine::ssl_protocol,
    ssl_cipher           => $::redmine::ssl_cipher_suite,
    ssl_honorcipherorder => 'On',
    require              => File['redmine_link']
  }
}

# vim: set et sw=2:
