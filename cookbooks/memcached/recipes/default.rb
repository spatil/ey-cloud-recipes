#
# Cookbook Name:: memcached
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

if any_app_needs_recipe?("memcached")
  
  ey_cloud_report "memcached" do
    message "processing memcached"
  end

  require_recipe "monit"

  package "memcached" do
    action :install
  end

end

if_app_needs_recipe("memcached") do |app,data,index|


  memcached_service = find_app_service(app, "memcached")
  
  template "/etc/conf.d/memcached" do
    owner "root"
    group "root"
    mode 0644   
    variables({
      :app_name => app,
      :memcached_mem_limit => memcached_service[:mem_limit],
      :memcached_base_port => memcached_service[:base_port]
    })
    source "memcached.conf.erb"
    action :create_if_missing
  end
  
  template "/data/#{app}/shared/config/memcached.yml" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644   
    variables({
      :app_name => app,
      :backends => node[:members] || ['127.0.0.1'],
      :memcached_mem_limit => memcached_service[:mem_limit],
      :memcached_base_port => memcached_service[:base_port]
    })
    source "memcached.yml.erb"
  end
  
  monitrc "memcached", :memcached_base_port => memcached_service[:base_port]

end
