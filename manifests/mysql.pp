# == Class: redmine::mysql
#
# Configure MySQL.
#
# === Examples
#
#  include '::redmine::mysql'
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
class redmine::mysql () {

  include ::redmine

  if $::redmine::db_host == 'localhost' {
    include ::mysql::server
    mysql::db { $::redmine::db_name:
      user     => $::redmine::db_user,
      password => $::redmine::db_password,
      host     => $::redmine::db_host,
      charset  => $::redmine::db_charset,
      collate  => $::redmine::db_collate,
    }
  } else {
    include ::mysql::client
  }
}

# vim: set et sw=2:
