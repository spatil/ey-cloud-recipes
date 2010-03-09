#
# Cookbook Name:: ruby
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

ey_cloud_report "ruby" do
  message "processing #{node[:ruby_version] || 'ruby'}"
end

case node[:ruby_version]
when 'Ruby 1.8.6'

  # no-op until we can figure out why emerging 1.8.6 fails.
  #
  #package 'ruby' do
  #  version '1.8.6*'
  #end

when 'Ruby 1.8.7'

  execute "unmask ruby 1.8.7" do
    command "echo '=dev-lang/ruby-1.8.7*' >> /etc/portage/package.keywords/local"
  end

  package 'ruby' do
    version '1.8.7*'
  end

else
  # noop - use system installed ruby 1.8.6-p287-r2
end
