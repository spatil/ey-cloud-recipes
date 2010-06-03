#
# Cookbook Name:: memcached
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

if node.engineyard.recipes.include?(DNApi::Recipe::Memcached)
  ey_cloud_report "memcached" do
    message "processing memcached"
  end

  require_recipe "memcached::server" unless node[:quick]
  require_recipe "memcached::client"
end
