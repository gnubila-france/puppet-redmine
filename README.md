# Puppet module: redmine

[![Puppet Forge](http://img.shields.io/puppetforge/v/gnubilafrance/redmine.svg)](https://forge.puppetlabs.com/gnubilafrance/redmine)
[![Build Status](https://travis-ci.org/gnubila-france/puppet-redmine.png?branch=master)](https://travis-ci.org/gnubila-france/puppet-redmine)

This is a Puppet module for redmine
It provides only package installation and file configuration.

Based on Example42 layouts by Alessandro Franceschi / Lab42

Official site: http://gnubila.fr

Official git repository: http://github.com/gnubila-france/puppet-redmine

Released under the terms of MIT License.


## USAGE - Basic management

* Install redmine with default settings

        class { 'redmine': }

* Install a specific version of redmine package

        class { 'redmine':
          version => '1.0.1',
        }

* Remove redmine resources

        class { 'redmine':
          absent => true
        }

* Enable auditing without without making changes on existing redmine configuration *files*

        class { 'redmine':
          audit_only => true
        }

* Module dry-run: Do not make any change on *all* the resources provided by the module

        class { 'redmine':
          noops => true
        }


## USAGE - Overrides and Customizations
* Use custom sources for main config file

        class { 'redmine':
          source => [
	  "puppet:///modules/site/redmine/redmine.conf-${hostname}" ,
	  "puppet:///modules/site/redmine/redmine.conf" ],
        }


* Use custom source directory for the whole configuration dir

        class { 'redmine':
          source_dir       => 'puppet:///modules/site/redmine/conf/',
          source_dir_purge => false, # Set to true to purge any existing file not present in $source_dir
        }

* Use custom template for main config file. Note that template and source arguments are alternative.

        class { 'redmine':
          template => 'site/redmine/redmine.conf.erb',
        }

* Automatically include a custom subclass

        class { 'redmine':
          my_class => 'site::my_redmine',
        }



## TESTING
[![Build
Status](https://travis-ci.org/gnubila-france/puppet-redmine.png?branch=master)](https://travis-ci.org/gnubila-france/puppet-redmine)
