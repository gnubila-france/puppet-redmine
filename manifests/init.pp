# = Class: redmine
#
# This is the main redmine class
#
#
# == Parameters
#
# Standard class parameters
# Define the general class behaviour and customizations
#
# [*my_class*]
#   Name of a custom class to autoload to manage module's customizations
#   If defined, redmine class will automatically "include $my_class"
#   Can be defined also by the (top scope) variable $redmine_myclass
#
# [*source*]
#   Sets the content of source parameter for main configuration file
#   If defined, redmine main config file will have the param: source => $source
#   Can be defined also by the (top scope) variable $redmine_source
#
# [*source_dir*]
#   If defined, the whole redmine configuration directory content is retrieved
#   recursively from the specified source
#   (source => $source_dir , recurse => true)
#   Can be defined also by the (top scope) variable $redmine_source_dir
#
# [*source_dir_purge*]
#   If set to true (default false) the existing configuration directory is
#   mirrored with the content retrieved from source_dir
#   (source => $source_dir , recurse => true , purge => true)
#   Can be defined also by the (top scope) variable $redmine_source_dir_purge
#
# [*template*]
#   Sets the path to the template to use as content for main configuration file
#   If defined, redmine main config file has: content => content("$template")
#   Note source and template parameters are mutually exclusive: don't use both
#   Can be defined also by the (top scope) variable $redmine_template
#
# [*options*]
#   An hash of custom options to be used in templates for arbitrary settings.
#   Can be defined also by the (top scope) variable $redmine_options
#
# [*version*]
#   The package version, used in the ensure parameter of package type.
#   Default: present. Can be 'latest' or a specific version number.
#   Note that if the argument absent (see below) is set to true, the
#   package is removed, whatever the value of version parameter.
#
# [*absent*]
#   Set to 'true' to remove package(s) installed by module
#   Can be defined also by the (top scope) variable $redmine_absent
#
# [*audit_only*]
#   Set to 'true' if you don't intend to override existing configuration files
#   and want to audit the difference between existing files and the ones
#   managed by Puppet.
#   Can be defined also by the (top scope) variables $redmine_audit_only
#   and $audit_only
#
# [*noops*]
#   Set noop metaparameter to true for all the resources managed by the module.
#   Basically you can run a dryrun for this specific module if you set
#   this to true. Default: false
#
# Default class params - As defined in redmine::params.
# Note that these variables are mostly defined and used in the module itself,
# overriding the default values might not affected all the involved components.
# Set and override them only if you know what you're doing.
# Note also that you can't override/set them via top scope variables.
#
# [*account_view_dir*]
#   Application views account directory 
#
# [*login_page_file*]
#   File used to generate the Redmine login page 
#
# [*config_dir*]
#   Main configuration directory. Used by puppi
#
# [*config_file*]
#   Main configuration file path
#
# == Examples
#
# You can use this class in 2 ways:
# - Set variables (at top scope level on in a ENC) and "include redmine"
# - Call redmine as a parametrized class
#
# See README for details.
#
#
class redmine (
  String $db_type,
  String $db_adapter,
  String $db_name,
  String $db_user,
  String $db_password,
  String $db_host,
  String $db_charset,
  String $db_collate,
  String $webserver_type,
  String $vhost_template,
  String $server_name,
  String $serveraliases,
  Boolean $ssl,
  String $ssl_protocol,
  String $ssl_cipher_suite,
  String $ssl_cert,
  String $ssl_cert_src,
  String $ssl_cert_content,
  String $ssl_cert_key,
  String $ssl_cert_key_src,
  String $ssl_cert_key_content,
  String $ssl_ca_cert,
  String $ssl_ca_cert_src,
  String $ssl_ca_cert_content,
  String $ssl_ca_cert_chain,
  String $ssl_ca_cert_chain_src,
  String $ssl_ca_cert_chain_content,
  String $install_dir,
  Boolean $install_deps,
  String $email_delivery,
  String $smtp_server,
  String $smtp_domain,
  Integer $smtp_port,
  String $smtp_authentication,
  String $smtp_user_name,
  String $smtp_password,
  String $plugin_repo,
  #String $plugin_repo_proto,
  #String $plugin_repo_creds,
  String $version,
  String $ruby_version,
  String $passenger_version,
  String $user,
  String $group,
  String $user_home,
  String $my_class,
  String $source,
  String $source_dir,
  Boolean $source_dir_purge,
  String $template,
  String $db_template,
  String $bundle_config_template,
  String $options,
  Boolean $absent,
  Boolean $audit_only,
  Boolean $noops,
  String $account_view_dir,
  String $login_page_file,
  String $config_dir,
  String $config_file,
  String $config_file_mode,
  String $config_file_owner,
  String $config_file_group,
  String $db_config_file,
  String $install_url_base,
  String $attachments_storage_path,
  String $custom_files_url,
  Hash $plugins = '',
  String $rubygems_mirror = undef,
  ) {


  $bool_source_dir_purge=any2bool($source_dir_purge)
  $bool_absent=any2bool($absent)
  $bool_audit_only=any2bool($audit_only)
  $bool_noops=any2bool($noops)

  ### Definition of some variables used in the module
  $manage_file = $redmine::bool_absent ? {
    true    => 'absent',
    default => 'present',
  }

  $manage_audit = $redmine::bool_audit_only ? {
    true  => 'all',
    false => undef,
  }

  $manage_file_replace = $redmine::bool_audit_only ? {
    true  => false,
    false => true,
  }

  $manage_file_source = $redmine::source ? {
    ''        => undef,
    default   => $redmine::source,
  }

  $manage_file_content = $redmine::template ? {
    ''        => undef,
    default   => template($redmine::template),
  }

  $manage_db_file_content = $redmine::db_template ? {
    ''        => undef,
    default   => template($redmine::db_template),
  }

  $gemenv = hiera('redmine::gemenv')

  $path = [
    "${redmine::user_home}/bin",
    '/bin', '/usr/bin', '/sbin', '/usr/sbin', '/usr/local/bin',
  ]

  if $redmine::install_deps {
    include redmine::dependencies
    Class['redmine::dependencies'] ~> Class['redmine']
  }

  ### Managed resources
  user { $redmine::user:
    ensure     => 'present',
    home       => $redmine::user_home,
    managehome => true,
    shell      => '/bin/bash',
  }

  file { $redmine::user_home:
    ensure  => directory,
    mode    => '0755',
    seluser => 'system_u',
    require => User[$redmine::user],
  }

  $src_url = "${redmine::install_url_base}/redmine-${redmine::version}.tar.gz"
  puppi::netinstall { 'redmine':
    url             => $src_url,
    destination_dir => $redmine::user_home,
    owner           => $redmine::user,
    group           => $redmine::group,
    require         => User[$redmine::user],
  }

  file { 'redmine_link':
    ensure  => link,
    target  => "${redmine::user_home}/redmine-${redmine::version}",
    path    => "${redmine::user_home}/redmine",
    owner   => $redmine::user,
    group   => $redmine::group,
    seluser => 'system_u',
    require => Puppi::Netinstall['redmine'],
    notify  => Exec['update-login-page'],
  }

  exec { 'update-login-page':
     command => "/bin/cp /etc/puppetlabs/code/environments/production/modules/redmine/files/login.html.erb ${redmine::user_home}/redmine/app/views/account/login.html.erb",
     unless  => "/bin/grep -E 'Custom login page' ${redmine::user_home}/redmine/app/views/account/login.html.erb",
     notify  => Exec['fix-gemfile-issue'],
  }

  exec { 'fix-gemfile-issue':
     command => "/bin/sed -i -- 's/gem \"nokogiri\", \">= 1.6.7.2\"/gem \"nokogiri\", \"~> 1.6.7.2\"/g' ${redmine::user_home}/redmine/Gemfile",
     unless  => "/bin/grep -E 'nokogiri.*~> 1.6.7.2' ${redmine::user_home}/redmine/Gemfile",
     notify  => File['redmine.conf'],
  }

  file { 'redmine.conf':
    ensure  => $redmine::manage_file,
    path    => $redmine::config_file,
    mode    => $redmine::config_file_mode,
    owner   => $redmine::config_file_owner,
    group   => $redmine::config_file_group,
    seluser => 'system_u',
    require => File['redmine_link'],
    content => $redmine::manage_file_content,
    replace => $redmine::manage_file_replace,
    audit   => $redmine::manage_audit,
    noop    => $redmine::bool_noops,
    notify  => File['redmine-database.conf'],
  }

  file { 'redmine-database.conf':
    ensure  => $redmine::manage_file,
    path    => $redmine::db_config_file,
    mode    => $redmine::config_file_mode,
    owner   => $redmine::config_file_owner,
    group   => $redmine::config_file_group,
    seluser => 'system_u',
    require => File['redmine_link'],
    content => $redmine::manage_db_file_content,
    replace => $redmine::manage_file_replace,
    audit   => $redmine::manage_audit,
    noop    => $redmine::bool_noops,
    notify  => Class["redmine::${redmine::db_type}"],
  }

  # The whole redmine configuration directory can be recursively overriden
  if $redmine::source_dir and $redmine::source_dir != '' {
    file { 'redmine.dir':
      ensure  => directory,
      path    => $redmine::config_dir,
      require => File['redmine_link'],
      source  => $redmine::source_dir,
      recurse => true,
      purge   => $redmine::bool_source_dir_purge,
      force   => $redmine::bool_source_dir_purge,
      replace => $redmine::manage_file_replace,
      audit   => $redmine::manage_audit,
      noop    => $redmine::bool_noops,
    }
  }

  if $redmine::attachments_storage_path and $redmine::attachments_storage_path != '' {
    exec { 'parents_of_attachments_storage_path':
      command => "mkdir -p ${redmine::attachments_storage_path} 2> /dev/null",
      path    => $path,
      creates => $redmine::attachments_storage_path,
      require => User[$redmine::user],
      notify  => File[$redmine::attachments_storage_path],
    }

    file { $redmine::attachments_storage_path:
      ensure  => directory,
      path    => $redmine::attachments_storage_path,
      owner   => $redmine::user,
      group   => $redmine::group,
      require => Exec['parents_of_attachments_storage_path'],
      recurse => true,
    }
  }

  ### Include custom class if $my_class is set
  if $redmine::my_class and $redmine::my_class != '' {
    include $redmine::my_class
  }

  # set up database
  include "redmine::${redmine::db_type}"

  # manage rubygems mirror in .bundle/config
  if $redmine::rubygems_mirror != '' {

    file { "${redmine::install_dir}/.bundle":
      ensure  => directory,
      owner   => $redmine::user,
      group   => $redmine::group,
      seluser => 'system_u',
      mode    => '0750',
      require => File[$redmine::install_dir],
    }

    file { "${redmine::install_dir}/.bundle/config":
      ensure  => file,
      replace => 'no',
      owner   => $redmine::user,
      group   => $redmine::group,
      mode    => '0640',
      seluser => 'system_u',
      require => File["${redmine::install_dir}/.bundle"],
      content => template($redmine::bundle_config_template),
      before  => Exec['Install gems using bundler'],
    }

  }

  exec { 'Install gems using bundler':
    command     => "bundle install --path ${redmine::user_home}/.gem",
    user        => $redmine::user,
    cwd         => $redmine::install_dir,
    path        => $path,
    environment => $gemenv,
    require     => Class['devops::ruby'],
    notify      => Exec['Generate secret token'],
    unless  => "bundle check",
  }

  exec { 'Generate secret token':
    command     => 'bundle exec rake generate_secret_token',
    user        => $redmine::user,
    cwd         => $redmine::install_dir,
    path        => $path,
    environment => $gemenv,
    refreshonly => true,
    require     => Exec['Install gems using bundler'],
    notify      => Exec['Run database migration'],
  }

  exec { 'Run database migration':
    command     => 'bundle exec rake db:migrate',
    user        => $redmine::user,
    cwd         => $redmine::install_dir,
    path        => $path,
    environment => $gemenv,
    refreshonly => true,
    require     => [ Exec['Install gems using bundler'], Class["redmine::${redmine::db_type}"] ],
  }

#  TODO: create a boolean for this.  for now, don't load data
#  exec { 'Insert default data set':
#    command     => 'bundle exec rake redmine::load_default_data',
#    user        => $redmine::user,
#    cwd         => $redmine::install_dir,
#    path        => $path,
#    environment => [ 'RAILS_ENV=production', 'REDMINE_LANG=en' ],
#    refreshonly => true,
#  }

  if $redmine::plugins != undef and is_hash($redmine::plugins) {
    create_resources('::redmine::plugin', $redmine::plugins)
  }

  if $redmine::custom_files_url != '' {
    puppi::netinstall { 'redmine_custom':
      url             => $redmine::custom_files_url,
      destination_dir => "${redmine::install_dir}/custom",
      extracted_dir   => '.',
      owner           => $redmine::user,
      group           => $redmine::group,
      require         => File['redmine_link'],
    }

    # safety limitation in netinstall prevents going directly to desired target
    exec { 'rsync custom to app':
      command => "/usr/bin/rsync -r ${redmine::install_dir}/custom/ ${redmine::install_dir}/",
      path    => $path,
      user    => $redmine::user,
      require => Puppi::Netinstall['redmine_custom'],
      unless  => "/usr/bin/rsync -nri ${redmine::install_dir}/custom/ ${redmine::install_dir}/ | /usr/bin/wc -l",
    }

  }

}

# vim: set et sw=2:
