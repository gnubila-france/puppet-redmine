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
  $db_type             = params_lookup( 'db_type' ),
  $db_name             = params_lookup( 'db_name' ),
  $db_user             = params_lookup( 'db_user' ),
  $db_password         = params_lookup( 'db_password' ),
  $db_host             = params_lookup( 'db_host' ),
  $webserver_type      = params_lookup( 'webserver_type' ),
  $vhost_template      = params_lookup( 'vhost_template' ),
  $install_dir         = params_lookup( 'install_dir' ),
  $version             = params_lookup( 'version' ),
  $owner               = params_lookup( 'owner' ),
  $group               = params_lookup( 'group' ),
  $my_class            = params_lookup( 'my_class' ),
  $source              = params_lookup( 'source' ),
  $source_dir          = params_lookup( 'source_dir' ),
  $source_dir_purge    = params_lookup( 'source_dir_purge' ),
  $template            = params_lookup( 'template' ),
  $db_template         = params_lookup( 'db_template' ),
  $options             = params_lookup( 'options' ),
  $absent              = params_lookup( 'absent' ),
  $audit_only          = params_lookup( 'audit_only' , 'global' ),
  $noops               = params_lookup( 'noops' ),
  $config_dir          = params_lookup( 'config_dir' ),
  $config_file         = params_lookup( 'config_file' )
  ) inherits redmine::params {

  $config_file_mode=$redmine::params::config_file_mode
  $config_file_owner=$redmine::params::config_file_owner
  $config_file_group=$redmine::params::config_file_group

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

  $db_adapter = $redmine::db_type ? {
    'mysql' => 'mysql2',
    default => $redmine::db_type,
  }

  ### Managed resources
  user { $redmine::owner:
    ensure     => 'present',
    home       => $redmine::install_dir,
    managehome => true,
    shell      => "/bin/bash",
  }

  $src_url = "${redmine::install_url_base}/redmine-${redmine::version}.tar.gz"
  puppi::netinstall { 'redmine':
    url             => $src_url,
    destination_dir => $redmine::install_dir,
    owner           => $redmine::owner,
    group           => $redmine::group,
    require         => User[$redmine::owner],
  }
  file { 'redmine_link':
    ensure  => 'link',
    target  => "${redmine::install_dir}/redmine-${redmine::version}",
    path    => "${redmine::install_dir}/redmine",
    require => Puppi::Netinstall['redmine'],
  }

  $fileconf_require = $redmine::install_type ? {
    'source'  => File['redmine_link'],
    'package' => Package[$redmine::package],
  }

  file { 'redmine.conf':
    ensure  => $redmine::manage_file,
    path    => $redmine::config_file,
    mode    => $redmine::config_file_mode,
    owner   => $redmine::config_file_owner,
    group   => $redmine::config_file_group,
    require => $redmine::fileconf_require,
    content => $redmine::manage_file_content,
    replace => $redmine::manage_file_replace,
    audit   => $redmine::manage_audit,
    noop    => $redmine::bool_noops,
  }

  file { 'redmine-database.conf':
    ensure  => $redmine::manage_file,
    path    => $redmine::db_config_file,
    mode    => $redmine::config_file_mode,
    owner   => $redmine::config_file_owner,
    group   => $redmine::config_file_group,
    require => $redmine::fileconf_require,
    content => $redmine::manage_db_file_content,
    replace => $redmine::manage_file_replace,
    audit   => $redmine::manage_audit,
    noop    => $redmine::bool_noops,
  }

  # The whole redmine configuration directory can be recursively overriden
  if $redmine::source_dir {
    file { 'redmine.dir':
      ensure  => directory,
      path    => $redmine::config_dir,
      require => $redmine::fileconf_require,
      source  => $redmine::source_dir,
      recurse => true,
      purge   => $redmine::bool_source_dir_purge,
      force   => $redmine::bool_source_dir_purge,
      replace => $redmine::manage_file_replace,
      audit   => $redmine::manage_audit,
      noop    => $redmine::bool_noops,
    }
  }

  ### Include custom class if $my_class is set
  if $redmine::my_class {
    include $redmine::my_class
  }

  include redmine::dependencies

  # Setup database
  include "redmine::${redmine::db_type}"

  # Setup webserver
  if $redmine::webserver_type != undef {
    include "redmine::${redmine::webserver_type}"

    Class["::redmine::${redmine::db_type}"]->
    Class["::redmine::${redmine::webserver_type}"]
  }
}

# vim: set et sw=2:
