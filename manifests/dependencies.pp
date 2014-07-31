class redmine::dependencies {
  package { 'imagemagick':
    ensure => $redmine::manage_package,
  }
  if $redmine::db_type == 'mysql' {
    package { 'ruby-mysql2':
      ensure => $redmine::manage_package,
    }
  }
}

# vim: set et sw=2:
