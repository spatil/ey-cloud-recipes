#
# Cookbook Name:: ruby
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

ruby_install "System Ruby" do
  label node[:ruby_version] || 'Ruby 1.8.6'
end
