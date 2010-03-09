#
# Cookbook Name:: unicorn
# Recipe:: default
#
# Copyright 2009, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

if any_app_needs_recipe?('unicorn')

  ey_cloud_report "unicorn" do
    message "processing unicorn"
  end

  gem_package 'unicorn' do
    action :install
  end

  directory "/var/log/engineyard/unicorn" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
  end

  directory "/var/run/engineyard/" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
  end

end

if_app_needs_recipe("unicorn") do |app,data,index|

  app_type = (data[:type] == 'rails' ? 'rails' : 'rack')

  template "/etc/conf.d/unicorn_#{app}" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    variables({
      :app => app,
      :user => node[:owner_name],
      :type => app_type,
      :framework_env => node[:environment][:framework_env]
    })
    source "unicorn.confd.erb"
  end

  template "/etc/init.d/unicorn_#{app}" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0777
    source "unicorn.initd.erb"
    variables({
      :app_type => app_type
    })
  end

  directory "/var/run/unicorn/#{app}" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
    recursive true
  end

  unicorn_instance_count = (get_mongrel_count / node[:applications].size)

  template "/data/#{app}/shared/config/unicorn.rb" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    variables({
      :unicorn_instance_count => unicorn_instance_count,
      :app => app,
      :user => node[:owner_name]
    })
    source "unicorn.rb.erb"
  end

  execute "add-unicorn-for-#{app}-to-default-runlevel" do
    command "rc-update add unicorn_#{app} default"
    action :run
    not_if "rc-status | grep unicorn_#{app}"
  end

end
