# == Define: redmine::plugin
#
# Define allowing to install a redmine plugin
#
# === Parameters
#
# Document parameters here.
#
# === Examples
#
#  'redmine::plugin' { 'namevar':
#    parameter1 => [ 'just', 'an', 'example', ]
#  }
#
# === Authors
#
# Baptiste Grenier <bgrenier@gnubila.fr>
#
# === Copyright
#
# Copyright 2015 gnúbila
#
define redmine::plugin (
  $user = $redmine::user,
  $group = $redmine::group,
  $repo_url = undef,
  $revision = 'master',
  $provider = 'git',
) {
  include ::redmine

  if $repo_url == undef {
    fail('Please provide rep_url.')
  }
  vcsrepo { "${redmine::install_dir}/plugins/${title}":
    ensure   => 'present',
    provider => $provider,
    source   => $repo_url,
    revision => $revision,
    user     => $user,
    notify   => Exec["Update gems environment using bundler for plugin ${title}"],
    require  => File['redmine_link'],
  }

  $path = [
    "${redmine::user_home}/bin",
    '/bin', '/usr/bin', '/usr/sbin'
  ]
  exec { "Update gems environment using bundler for plugin ${title}":
    command     => 'bundle update',
    user        => $user,
    cwd         => "${redmine::install_dir}/plugins/${title}",
    path        => $path,
    refreshonly => true,
    notify      => Exec["Install gems using bundler for plugin ${title}"],
    require     => Exec['Install gems using bundler'],
  }
  exec { "Install gems using bundler for plugin ${title}":
    command     => 'bundle install --without development test',
    user        => $user,
    cwd         => "${redmine::install_dir}/plugins/${title}",
    path        => $path,
    refreshonly => true,
    notify      => Exec["Run database migration for plugin ${title}"],
    require     => Exec['Install gems using bundler'],
  }

  exec { "Run database migration for plugin ${title}":
    command     => 'bundle exec rake redmine:plugins:migrate',
    user        => $user,
    cwd         => $redmine::install_dir,
    path        => $path,
    environment => [ 'RAILS_ENV=production' ],
    refreshonly => true,
    require     => Exec['Run database migration'],
  }
}

# vim: set et sw=2:
