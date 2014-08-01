# Define allowing to install a redmine plugin
define redmine::plugin (
  $user = $redmine::owner,
  $group = $user,
  $redmine_home = "${redmine::install_dir}/redmine",
  $repo_url = undef,
  $revision = 'master',
  $provider = 'git',
) {
  include ::redmine

  if $repo_url == undef {
    fail('Please provide rep_url.')
  }
  vcsrepo { "${redmine_home}/plugins/${title}":
    ensure   => 'present',
    provider => $provider,
    source   => $repo_url,
    revision => $revision,
    user     => $user,
    notify   => Exec["Update gems environment using bundler for plugin ${title}"],
  }

  $path = [
    "${redmine::install_dir}/.rbenv/shims",
    "${redmine::install_dir}/.rbenv/bin",
    '/bin', '/usr/bin', '/usr/sbin'
  ]
  exec { "Update gems environment using bundler for plugin ${title}":
    command     => 'bundle update',
    user        => $user,
    cwd         => "${redmine_home}/plugins/${title}",
    path        => $path,
    refreshonly => true,
    notify      => Exec["Install gems using bundler for plugin ${title}"],
  }
  exec { "Install gems using bundler for plugin ${title}":
    command     => 'bundle install --without development test',
    user        => $user,
    cwd         => "${redmine_home}/plugins/${title}",
    path        => $path,
    refreshonly => true,
    notify      => Exec["Run database migration for plugin ${title}"],
  }

  exec { "Run database migration for plugin ${title}":
    command     => 'bundle exec rake redmine::plugins::migrate',
    user        => $user,
    cwd         => $redmine_home,
    path        => $path,
    environment => [ "RAILS_ENV=production" ],
    refreshonly => true,
  }
}

# vim: set et sw=2:
