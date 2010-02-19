#
# Cookbook Name:: deploy
# Recipe:: default
#
# Copyright 2009, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

require 'chef-deploy'

applications_to_deploy.each do |app, data|
  
  msg = if (data[:run_migrations] && ['solo', 'app_master'].include?(node[:instance_role]))
    "deploying & migrating #{app}"
  else
    "deploying #{app}"
  end
  
  if data[:deploy_action] == 'rollback'
    msg = "rolling back #{app}"
  end
  
  ey_cloud_report "deploying: #{app}" do
    message msg
  end
  
  cmd = ""
  if any_app_needs_recipe?('passenger')
    cmd = "touch /data/#{app}/current/tmp/restart.txt"
  elsif any_app_needs_recipe?('nginx-passenger')
    cmd = "touch /data/#{app}/current/tmp/restart.txt"
  end
  
  if node[:instance_role] == 'util'
    cmd = ""
  end
  
  template "/home/#{node[:owner_name]}/.ssh/config" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0600
    source "ssh-config.erb"
    variables({
      :apps => [app]
    })
  end

  template "/root/.ssh/config" do
    owner 'root'
    group 'root'
    mode 0600
    source "ssh-config.erb"
    variables({
      :apps => [app]
    })
  end

  deploy "/data/#{app}" do
    repo data[:repository_name]
    branch data[:branch]
    role node[:instance_role]
    environment node[:environment][:framework_env]
    user node[:owner_name]
    restart_command cmd
    revision data[:revision]
    enable_submodules true
    migrate (data[:run_migrations] && ['solo', 'app_master'].include?(node[:instance_role])) 
    migration_command data[:migration_command]
    action data[:deploy_action]
  end
  
  execute "ensure-permissions-for-#{app}" do
    command "chown -R #{node[:owner_name]}:#{node[:owner_name]} /data/#{app}"
  end
  
end


template "/home/#{node[:owner_name]}/.ssh/config" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0600
  source "ssh-config.erb"
  variables({
    :apps => node[:keys_to_add]
  })
end

template "/root/.ssh/config" do
  owner 'root'
  group 'root'
  mode 0600
  source "ssh-config.erb"
  variables({
    :apps => node[:keys_to_add]
  })
end
