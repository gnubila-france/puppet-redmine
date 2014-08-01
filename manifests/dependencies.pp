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
    notify  => Exec['Update gems list using bundler'],
  }

  $path = [ 
    "${home_path}/.rbenv/shims",
    "${home_path}/.rbenv/bin",
    '/bin', '/usr/bin', '/usr/sbin'
  ]
  $redmine_path = "${redmine::install_dir}/redmine" 
  exec { 'Update gems list using bundler':
    command     => 'bundle update',
    user        => $redmine::owner,
    cwd         => $redmine_path,
    path        => $path,
    onlyif      => "[ -e '${redmine_path}/Gemfile.lock' ]",
    refreshonly => true,
    require     => Rbenv::Compile["${redmine::owner}/${redmine::ruby_version}"],
  }
  exec { 'Install gems using bundler':
    command     => 'bundle install --without development test',
    user        => $redmine::owner,
    cwd         => $redmine_path,
    path        => $path,
    refreshonly => true,
    require     => Rbenv::Compile["${redmine::owner}/${redmine::ruby_version}"],
  }
}

# vim: set et sw=2:
