#
# Cookbook Name:: unicorn
# Recipe:: default
#
# Copyright 2009, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

ey_cloud_report "unicorn" do
  message "processing unicorn"
end

gem_package 'unicorn' do
  version "0.97.1"
  action :install
end

directory "/var/log/engineyard/unicorn" do
  owner node.engineyard.environment.ssh_username
  group node.engineyard.environment.ssh_username
  mode 0755
end

directory "/var/run/engineyard" do
  owner node.engineyard.environment.ssh_username
  group node.engineyard.environment.ssh_username
  action :create
  mode 0755
end

node.engineyard.apps.each do |app|
  template "/etc/conf.d/unicorn_#{app.name}" do
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode 0644
    variables({
      :app => app.name,
      :user => node.engineyard.environment.ssh_username,
      :type => app.type,
      :framework_env => node.engineyard.environment.framework_env
    })
    source "unicorn.confd.erb"
  end

  template "/etc/init.d/unicorn_#{app.name}" do
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode 0777
    source "unicorn.initd.erb"
    variables({
      :app_type => app.type
    })
  end

  directory "/var/run/unicorn/#{app.name}" do
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode 0755
    recursive true
  end

  unicorn_instance_count = (get_mongrel_count / node.engineyard.apps.size)
  unicorn_worker_count = unicorn_instance_count - 1

  template "/etc/monit.d/unicorn_#{app.name}.monitrc" do
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode 0600
    source "unicorn.monitrc.erb"
    variables(
      :app => app.name,
      :user => node.engineyard.environment.ssh_username,
      :app_type => app.type,
      :unicorn_worker_count => unicorn_worker_count,
      :environment => node.engineyard.environment.framework_env
    )
    backup 0
  end
  
  template "/data/#{app.name}/shared/config/unicorn.rb" do
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode 0644
    variables({
      :unicorn_instance_count => unicorn_instance_count,
      :app => app.name,
      :type => app.type,
      :user => node.engineyard.environment.ssh_username
    })
    source "unicorn.rb.erb"
  end

  runlevel "unicorn_#{app.name}" do
    action :add
  end
end
