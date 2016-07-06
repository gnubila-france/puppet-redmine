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
  String $version,
  String $plugin_repo = $redmine::plugin_repo,
  String $plugin_repo_creds = $redmine::plugin_repo_creds,
  String $plugin_repo_proto = $redmine::plugin_repo_proto,
  String $user = $redmine::user,
  String $group = $redmine::group,
  #String $repo_url,
  #String $revision,
  #String $provider,
) {
  include ::redmine

#  if $repo_url == undef {
#    fail('Please provide rep_url.')
#  }
#
#  vcsrepo { "${redmine::install_dir}/plugins/${title}":
#    ensure   => 'present',
#    provider => $provider,
#    source   => $repo_url,
#    revision => $revision,
#    user     => $user,
#    notify   => Exec["Update gems environment using bundler for plugin ${title}"],
#    require  => File['redmine_link'],
#  }


  puppi::netinstall { $title:
    url             => "${redmine::plugin_repo_proto}://${redmine::plugin_repo_creds}@${redmine::plugin_repo}/${title}/$version/${title}-${version}.zip",
    destination_dir => "${redmine::user_home}/redmine-${redmine::version}/plugins/",
    extracted_dir   => "$title",
    #destination_dir => "${redmine::user_home}/redmine-${redmine::version}/plugins/extract_$title",
    #postextract_command => "mv ${redmine::user_home}/redmine-${redmine::version}/plugins/extract_$title ${redmine::user_home}/redmine-${redmine::version}/plugins/$title", 
    owner           => $user,
    group           => $group,
    #require         => 'redmine::redmine-database.conf',
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
