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
}

# vim: set et sw=2:
