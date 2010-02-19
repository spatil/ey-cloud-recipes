#
# Cookbook Name:: backups
# Recipe:: default
#
# Copyright 2009, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#
ey_cloud_report "backups" do
  message 'processing backups'
end

directory "/mnt/backups" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0755
end

template "/etc/.mysql.backups.yml" do
  owner 'root'
  group 'root'
  mode 0600
  source "mysql.backups.yml.erb"
  variables({
    :dbuser => 'root', 
    :dbpass => node[:owner_pass],
    :keep   => node[:backup_window] || 14,
    :id     => node[:aws_secret_id],
    :key    => node[:aws_secret_key],
    :env    => node[:environment][:name]
  })
end
