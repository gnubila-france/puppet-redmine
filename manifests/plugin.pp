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
    notify   => Exec["Run database migration for plugin ${title}"],
  }

  exec { "Run database migration for plugin ${title}":
    command     => 'bundle exec rake redmine::plugins::migrate',
    user        => $redmine::owner,
    cwd         => $redmine_path,
    path        => $path,
    environment => [ "RAILS_ENV=production" ],
    refreshonly => true,
  }
}

# vim: set et sw=2:
