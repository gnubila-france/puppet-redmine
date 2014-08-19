class redmine::apache(
  $user = $redmine::owner,
  $group = $user,
  $redmine_home = "${redmine::install_dir}/redmine",
  $template_passenger = params_lookup( 'template_passenger' ),
) inherits redmine::params {
  include ::redmine
  include ::apache

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

  $path = [
    "${redmine::install_dir}/.rbenv/shims",
    "${redmine::install_dir}/.rbenv/bin",
    '/bin', '/usr/bin', '/usr/sbin'
  ]
  exec { "gem install passenger --version ${passenger_version} --no-ri --no-rdoc":
    user   => $user,
    cwd    => $redmine_home,
    path   => $path,
    unless => "gem list passenger | grep -q '^passenger.*${passenger_version}'",
    notify => Exec['passenger-install-apache2-module -a'],
  }
  exec { 'passenger-install-apache2-module -a':
    user        => $user,
    cwd         => $redmine_home,
    path        => $path,
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
