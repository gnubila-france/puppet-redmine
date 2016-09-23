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
) {
  include ::redmine

  $path = [
    "${redmine::user_home}/bin", 
    '/bin', '/usr/bin', '/usr/sbin', '/usr/local/bin'
  ]

  $gemenv = hiera('redmine::gemenv')
  $appdir = "${redmine::user_home}/redmine-${redmine::version}"

  puppi::netinstall { $title:
    url             => "${redmine::plugin_repo_proto}://${redmine::plugin_repo_creds}@${redmine::plugin_repo}/${title}/$version/${title}-${version}.zip",
    destination_dir     => "$appdir/plugins/",
    extracted_dir       => "$title",
    owner               => $user,
    group               => $group,
    notify              => Exec["Install gems using bundler for plugin ${title}"],
    require             => File['redmine-database.conf'],
  }

  exec { "Install gems using bundler for plugin ${title}":
    command     => 'bundle install',
    user        => $user,
    cwd         => "${redmine::install_dir}",
    path        => $path,
    environment => $gemenv,
    refreshonly => true,
    require     => Exec["Install gems using bundler"],
    notify      => Exec["update db schema for plugin ${title}"],
  }

  exec { "update db schema for plugin ${title}":
    command     => 'bundle exec rake db:migrate',
    user        => $user,
    cwd         => "${redmine::install_dir}/plugins",
    path        => $path,
    environment => $gemenv,
    refreshonly => true,
    require     => [ Exec["Install gems using bundler for plugin ${title}"], Class["redmine::${redmine::db_type}"] ],
    notify      => Exec["Run plugin migration for plugin ${title}"],
  }

  exec { "Run plugin migration for plugin ${title}":
    command     => 'bundle exec rake redmine:plugins:migrate',
    user        => $user,
    cwd         => $redmine::install_dir,
    path        => $path,
    environment => $gemenv,
    refreshonly => true,
    require     => Exec["update db schema for plugin ${title}"],
  }

  file { "$appdir/plugins/$title":
    require => Exec["Run plugin migration for plugin ${title}"],
    recurse => true,
    owner   => $user,
    group   => $user,
    mode    => "0644",
  }

  file { "$appdir/public/plugin_assets/$title":
    require => Exec["Run plugin migration for plugin ${title}"],
    recurse => true,
    owner   => $user,
    group   => $user,
    mode    => "0644",
  }


}

# vim: set et sw=2:
