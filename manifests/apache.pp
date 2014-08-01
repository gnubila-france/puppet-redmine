class redmine::apache(
  $user = $redmine::owner,
  $group = $user,
  $redmine_home = "${redmine::install_dir}/redmine",
  $template_passenger = params_lookup( 'template_passenger' ),
) inherits redmine::params {
  include ::redmine
  include ::apache::passenger

  # SSL setup to be done
  #include apache::ssl
  # Required for redirection to https
  #if ! defined(Apache::Module['rewrite']) {
  # apache::module { 'rewrite':
  #   ensure => 'present',
  # }
  #}
  # Redirect http to https
  #apache::vhost { "${::hostname}-80":
  #  server_name => $::hostname,
  #  template    => 'site/apache/vhost_redirect_ssl.erb',
  #}

  exec { 'bundle exec gem install passenger --no-ri --no-rdoc':
    user   => $user,
    cwd    => $redmine_home,
    unless => 'bundle exec gem list passenger | grep -q \'^passenger \'',
    notify => Exec['passenger-install-apache2-module -a'],
  }
  exec { 'passenger-install-apache2-module -a':
    user        => $user,
    cwd         => $redmine_home,
    refreshonly => true,
  }

  file { [ "${redmine_home}/public", "${redmine_home}/tmp" ]:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
  }

  file { "${redmine_home}/config.ru":
    ensure  => 'present',
    owner   => $user,
    group   => $user,
    mode    => '0644',
  }

  $vhost_priority = 10
  $rack_location = "${redmine_home}/public/"
  apache::vhost { 'redmine':
    priority => $vhost_priority,
    docroot  => $rack_location,
    ssl      => true,
    template => $redmine::template_passenger,
    require  => File['redmine_link']
  }
}

# vim: set et sw=2:
