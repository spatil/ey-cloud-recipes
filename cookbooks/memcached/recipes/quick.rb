#
# Cookbook Name:: memcached
# Recipe:: quick
#
# Copyright 2009, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

if node[:members]
  if_app_needs_recipe("memcached") do |app,data,index|

    memcached_service = find_app_service(app, "memcached")

    ey_cloud_report "memcached" do
      message "processing memcached"
    end

    template "/data/#{app}/shared/config/memcached.yml" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0644
      variables({
        :app_name => app,
        :backends => node[:members],
        :memcached_mem_limit => memcached_service[:mem_limit],
        :memcached_base_port => memcached_service[:base_port]
      })
      source "memcached.yml.erb"
    end
  end
end
