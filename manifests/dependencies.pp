class redmine::dependencies {
  package { 'imagemagick':
    ensure => 'present',
  }
  package { 'libmagickwand-dev':
    ensure => 'present',
  }
  case $redmine::db_type {
    /^mysql/: {
      package { 'libmysqlclient-dev':
        ensure => 'present',
      }
    }
    'pgsql': {
      package { 'libpq-dev':
        ensure => 'present',
      }
    }
  }

  if $redmine::webserver_type == 'apache' {
    package { 'libcurl4-openssl-dev':
      ensure => 'present',
    }
    package { 'apache2-threaded-dev':
      ensure => 'present',
    }
    package { 'libapr1-dev':
      ensure => 'present',
    }
    package { 'libaprutil1-dev':
      ensure => 'present',
    }
  }
}

# vim: set et sw=2:
