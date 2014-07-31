class redmine::dependencies {
  package { 'rubygems':
    ensure => $redmine::manage_package,
  }
  package { 'rake':
    ensure => $redmine::manage_package,
  }
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
