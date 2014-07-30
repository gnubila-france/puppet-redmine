class redmine::mysql {
  if $::redmine::db_host == 'localhost' {
    include ::mysql
    mysql::grant { "${::redmine::db_name}: ${::redmine::db_user} at ${::redmine::db_host}":
      mysql_password   => $::redmine::db_password,
      mysql_db         => $::redmine::db_name,
      mysql_user       => $::redmine::db_user,
      mysql_host       => $::redmine::db_host,
    }
  } else {
    include ::mysql::client
  }
}

# vim: set et sw=2:
