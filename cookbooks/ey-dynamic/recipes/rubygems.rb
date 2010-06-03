#
# Cookbook Name:: ey-dynamic
# Recipe:: rubygems
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

## EY role acount should come first in the node[:users] array

ey_cloud_report "rubygems" do
  message "processing rubygems"
end

bash 'remove-mirror-from-etc-hosts' do
  code "sed -i -e '/^.*gems\.rubyforge\.org.*$/d' /etc/hosts"
end

node[:gems_to_install].each do |pkg|
  next if has_gem?(pkg[:name], pkg[:version].empty? ? nil : pkg[:version])
  gem_package pkg[:name] do
    if pkg[:version] && !pkg[:version].empty?
      version pkg[:version]
    end
    if pkg[:source] && !pkg[:source].empty?
      source pkg[:source]
    end
    action :install
  end
end

bash "remove engineyard gem source" do
  code <<-EOH
    gem sources -r http://gems.engineyard.com
  EOH
  only_if "gem sources | grep http://gems.engineyard.com"
end

gem_package "eyrubygems" do
  action :install
end
