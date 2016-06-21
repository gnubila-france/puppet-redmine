# == Class: redmine::dependencies
#
# Manage redmine dependencies
#
# === Parameters
#
# Document parameters here.
#
# === Examples
#
#  include '::redmine::dependencies'
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

class redmine::dependencies (
  String $pname_passenger,
  String $pname_mod_passenger,
  String $pname_imagemagick,
  String $pname_imagemagick_dev,
  String $pname_mysql_dev,
  String $pname_pgsql_dev,
  String $pname_openssl_dev,
  String $pname_apache_dev,
  String $pname_apr_dev,
  String $pname_apr_util_dev,
  ) {

  include ::redmine

  file { '/etc/yum.repos.d/passenger.repo':
    source => [
      "https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo",
      "puppet:///files/repos/passenger.repo",
    ]
  }

  package { $redmine::dependencies::pname_passenger: ensure => 'present' }
  package { $redmine::dependencies::pname_mod_passenger: ensure => 'present' }

  package { $redmine::dependencies::pname_imagemagick: ensure => 'present' }
  package { $redmine::dependencies::pname_imagemagick_dev: ensure => 'present' }

  case $redmine::db_type {
    /^mysql/: {
      package { $redmine::dependencies::pname_mysql_dev: ensure => 'present' }
    }
    'pgsql': {
      package { $redmine::dependencies::pname_pgsql_dev: ensure => 'present' }
    }
    default: {
      fail('Unsupported db_type')
    }
  }

  if $redmine::webserver_type == 'apache' {
    package { $redmine::dependencies::pname_openssl_dev: ensure => 'present' }
    package { $redmine::dependencies::pname_apache_dev: ensure => 'present' }
    package { $redmine::dependencies::pname_apr_dev: ensure => 'present' }
    package { $redmine::dependencies::pname_apr_util_dev: ensure => 'present' }
  }
}

# vim: set et sw=2:
