class redmine::dependencies {
  package { 'imagemagick':
    ensure => 'present',
  }
  if $redmine::db_type == 'mysql' {
    package { 'ruby-mysql2':
      ensure => 'present',
    }
  }

  rbenv::install { $redmine::owner:
    home    => $redmine::install_dir,
    require => User[$redmine::owner],
  }

  rbenv::compile { "${redmine::owner}/${redmine::ruby_version}":
    user    => $redmine::owner,
    home    => $redmine::install_dir,
    ruby    => $redmine::ruby_version,
    global  => true,
    require => Rbenv::Install[$redmine::owner],
    notify  => Exec['Update gems environment bundler'],
  }

  $path = [ 
    "${home_path}/.rbenv/shims",
    "${home_path}/.rbenv/bin",
    '/bin', '/usr/bin', '/usr/sbin'
  ]
  $redmine_path = "${redmine::install_dir}/redmine" 
  exec { 'Update gems environment bundler':
    command     => 'bundle update',
    user        => $redmine::owner,
    cwd         => $redmine_path,
    path        => $path,
    refreshonly => true,
    notify      => Exec['Install gems using bundler'],
    require     => File['redmine-database.conf'],
  }
  exec { 'Install gems using bundler':
    command     => 'bundle install --without development test',
    user        => $redmine::owner,
    cwd         => $redmine_path,
    path        => $path,
    refreshonly => true,
    require     => File['redmine-database.conf'],
  }
}

# vim: set et sw=2:
