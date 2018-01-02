require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'redmine' do

  let(:title) { 'redmine' }
  let(:node) { 'rspec.example42.com' }
  let(:facts) { { :ipaddress => '10.42.42.42' } }

  describe 'Test minimal installation' do
    it { should contain_file('redmine.conf').with_ensure('present') }
  end

  describe 'Test decommissioning - absent' do
    let(:params) { {:absent => true } }
    it 'should remove redmine configuration file' do should contain_file('redmine.conf').with_ensure('absent') end
  end

  describe 'Test noops mode' do
    let(:params) { {:noops => true} }
    it { should contain_file('redmine.conf').with_noop('true') }
  end

  describe 'Test customizations - template' do
    let(:params) { {:template => "redmine/spec.erb" , :options => { 'opt_a' => 'value_a' } } }
    it 'should generate a valid template' do
      content = catalogue.resource('file', 'redmine.conf').send(:parameters)[:content]
      content.should match "fqdn: rspec.example42.com"
    end
    it 'should generate a template that uses custom options' do
      content = catalogue.resource('file', 'redmine.conf').send(:parameters)[:content]
      content.should match "value_a"
    end
  end

  describe 'Test customizations - source' do
    let(:params) { {:source => "puppet:///modules/redmine/spec"} }
    it { should contain_file('redmine.conf').with_source('puppet:///modules/redmine/spec') }
  end

  describe 'Test customizations - source_dir' do
    let(:params) { {:source_dir => "puppet:///modules/redmine/dir/spec" , :source_dir_purge => true } }
    it { should contain_file('redmine.dir').with_source('puppet:///modules/redmine/dir/spec') }
    it { should contain_file('redmine.dir').with_purge('true') }
    it { should contain_file('redmine.dir').with_force('true') }
  end

  describe 'Test customizations - custom class' do
    let(:params) { {:my_class => "redmine::spec" } }
    it { should contain_file('redmine.conf').with_content(/rspec.example42.com/) }
  end

end
