source ENV['GEM_SOURCE'] || 'https://rubygems.org'

puppetversion = ENV.key?('PUPPET_VERSION') ? ENV['PUPPET_VERSION'] : ['>= 4.0']
gem 'metadata-json-lint'
#gem 'json', '>=1.8.3'
gem 'puppet', puppetversion
gem 'puppetlabs_spec_helper', '>= 1.0.0'
gem 'puppet-lint', '>= 1.0.0'
gem 'facter', '>= 1.7.0'
gem 'rspec-puppet'
gem 'ci_reporter_rspec', '>=1.0.0'

gem 'rake'
# rubocop requires ruby >= 1.9
gem 'rubocop'
