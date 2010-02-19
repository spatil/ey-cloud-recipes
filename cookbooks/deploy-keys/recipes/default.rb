#
# Cookbook Name:: deploy-keys
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#


ey_cloud_report "deploy keys" do
  message 'processing deploy keys'
end

directory "/home/#{node[:owner_name]}/.ssh" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0700
  action :create
end

node[:keys_to_add] = []

node[:applications].each do |app, data|
  if data[:deploy_key]
    node[:keys_to_add] << app
    execute "add-deploy-key-for-#{app}" do
      command %Q{
        echo '#{data[:deploy_key]}' > /root/.ssh/#{app}-deploy-key &&
        chmod  0600  /root/.ssh/#{app}-deploy-key &&
        echo '#{data[:deploy_key]}' > /home/#{node[:owner_name]}/.ssh/#{app}-deploy-key &&
        chmod  0600 /home/#{node[:owner_name]}/.ssh/#{app}-deploy-key &&
        chown  #{node[:owner_name]}:#{node[:owner_name]} /home/#{node[:owner_name]}/.ssh/#{app}-deploy-key
      }
    end
  end
end

