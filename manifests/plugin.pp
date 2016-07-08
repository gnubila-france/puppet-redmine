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
  String $bundle_without = $redmine::bundle_without,
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
    owner           => $user,
    group           => $group,
    notify          => Exec["Install gems using bundler for plugin ${title}"],
    #require         => 'redmine::redmine-database.conf',
  }

  $path = [
    "${redmine::user_home}/bin", 
    '/bin', '/usr/bin', '/usr/sbin'
  ]

#  exec { "Update gems environment using bundler for plugin ${title}":
#    command     => 'bundle update',
#    user        => $user,
#    cwd         => "${redmine::install_dir}/plugins/${title}",
#    path        => $path,
#    refreshonly => true,
#    notify      => Exec["Install gems using bundler for plugin ${title}"],
#    require     => Exec['Install gems using bundler'],
#  }
    $gemenv = [
      "HOME=$redmine::user_home",
      "BUNDLE_WITHOUT=--without xapian",
      #"BUNDLE_WITHOUT=--without $bundle_without",
      "RAILS_ENV=production",
      "RACK_ENV=production",
      #"DB_ADAPTER=mysql2",
      #"GEM_OPTIONS=--no-rdoc --no-ri"
    ]

  exec { "Install gems using bundler for plugin ${title}":
    #command     => 'bundle install --without development test',
    # TEMP - need to pass this in
    #command     => 'bundle install --without development:test:xapian',
    #command     => 'bundle install --path ${redmine::user_home}/.gem --without development:test:xapian',
    command     => 'bundle install ${BUNDLE_WITHOUT}',
    user        => $user,
    #cwd         => "${redmine::install_dir}/plugins/${title}",
    cwd         => "${redmine::install_dir}",
    path        => $path,
    environment => $gemenv,
    refreshonly => true,
    notify      => Exec["update db schema for plugin ${title}"],
    #require     => Exec["Update gems environment using bundler for plugin ${title}"],
  }

  exec { "update db schema for plugin ${title}":
    command     => 'bundle exec rake db:migrate',
    user        => $user,
    cwd         => "${redmine::install_dir}/plugins",
    path        => $path,
    environment => $gemenv,
    refreshonly => true,
    notify      => Exec["Run plugin migration for plugin ${title}"],
    require     => Exec["Install gems using bundler for plugin ${title}"],
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


}

# vim: set et sw=2:
