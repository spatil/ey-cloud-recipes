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

  require_recipe 'passenger::apache' if any_app_needs_recipe?('passenger')
end
