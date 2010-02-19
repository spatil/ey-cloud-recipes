#
# Cookbook Name:: passenger
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

if any_app_needs_recipe?("passenger") || any_app_needs_recipe?('nginx-passenger')

  ey_cloud_report "passenger" do
    message "processing passenger"
  end

  gem_package "passenger" do
    action :install
    version node[:passenger_version]
  end

  node[:applications].each do |app, data|

    directory "/var/log/engineyard/passenger/#{app}" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0755
      recursive true
    end

    link "/data/#{app}/shared/log" do
      to "/var/log/engineyard/passenger/#{app}" 
    end
  end

  logrotate "passenger" do
    files "/var/log/engineyard/passenger/*/*.log"
    copy_then_truncate true
  end

  require_recipe 'passenger::apache' if any_app_needs_recipe?('passenger')
end
