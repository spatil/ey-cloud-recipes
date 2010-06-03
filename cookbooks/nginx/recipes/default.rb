#
# Cookbook Name:: nginx
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

if node.engineyard.environment.stack.nginx?
  execute "restart-nginx" do
    command "/etc/init.d/nginx restart"
    action :nothing
  end

  ey_cloud_report "nginx" do
    message "processing nginx"
  end

  use_passenger = node.engineyard.environment.stack.passenger?

  package "nginx" do
    version '0.6.35-r25'
  end

  if use_passenger
    ey_cloud_report "nginx-passenger" do
      message "processing nginx-passenger"
    end

    remote_file '/usr/bin/ruby-for-passenger' do
      owner 'root'
      group 'root'
      mode 0755
      source 'ruby-for-passenger'
      notifies :run, resources(:execute => "restart-nginx"), :delayed
    end

    gem_package "fastthread" do
      action :install
    end
  end

  directory "/var/log/engineyard/nginx" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0775
  end

  %w{/data/nginx/servers /data/nginx/common}.each do |dir|
    directory dir do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0755
      recursive true
    end
  end

  unless File.symlink?("/var/log/nginx")
    directory "/var/log/nginx" do
      action :delete
      recursive true
    end
  end

  execute "remove /etc/nginx" do
    command "rm -rf /etc/nginx"
    action :run
  end

  link "/etc/nginx" do
    to "/data/nginx"
  end

  directory "/var/tmp/nginx/client" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0775
    recursive true
  end

  link "/var/log/nginx" do
    to "/var/log/engineyard/nginx"
  end

  remote_file "/etc/init.d/nginx" do
    owner "root"
    group "root"
    mode 0755
    source "nginx"
  end

  remote_file "/data/nginx/mime.types" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
    source "mime.types"
  end

  remote_file "/data/nginx/koi-utf" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
    source "koi-utf"
  end

  remote_file "/data/nginx/koi-win" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
    source "koi-win"
  end

  # This should become a service resource, once we have it for gentoo
  runlevel 'nginx' do
    action :add
  end

  logrotate "nginx" do
    files "/var/log/engineyard/nginx/*.log /var/log/engineyard/nginx/error_log"
    restart_command <<-SH
[ ! -f /var/run/nginx.pid ] || kill -USR1 `cat /var/run/nginx.pid`
    SH
  end

  pool_size = get_pool_size()

  managed_template "/etc/conf.d/nginx" do
    source "conf.d/nginx.erb"
    variables({
        :nofile => 16384
    })
    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end

  managed_template "/data/nginx/nginx.conf" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    source "nginx.conf.erb"
    variables({
      :use_passenger => use_passenger,
      :pool_size => pool_size
    })
    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end

  directory "/data/nginx/ssl" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0775
  end

  managed_template "/data/nginx/common/proxy.conf" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    source "common.proxy.conf.erb"
    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end

  managed_template "/data/nginx/common/servers.conf" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    source "common.servers.conf.erb"
    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end

  managed_template "/data/nginx/common/fcgi.conf" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    source "common.fcgi.conf.erb"
    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end

  file "/data/nginx/servers/default.conf" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end
end

(node[:removed_applications]||[]).each do |app|
  execute "remove-old-vhosts-for-#{app}" do
    command %Q{
      rm -rf /data/nginx/servers/#{app}* && /etc/init.d/nginx restart
    }
  end
end

if_app_needs_recipe("nginx") do |app,data,index|

  directory "/data/nginx/servers/#{app}" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0775
  end

  directory "/data/nginx/servers/#{app}/ssl" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0775
  end

  managed_template "/data/nginx/servers/#{app}.rewrites" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    source "server.rewrites.erb"
    action :create_if_missing
    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end

  managed_template "/data/nginx/servers/#{app}.users" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    source "users.erb"
    variables({
      :application => node[:applications][app]
    })
    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end

  managed_template "/data/nginx/servers/#{app}/custom.locations.conf" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    source "custom.locations.conf.erb"
    action :create_if_missing
    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end

  mongrel_service = find_app_service(app, "mongrel")
  fcgi_service = find_app_service(app, "fcgi")
  mongrel_base_port =  (mongrel_service[:mongrel_base_port].to_i + (index * 1000))
  mongrel_instance_count = (get_mongrel_count / node[:applications].size)
  unicorn = any_app_needs_recipe?('unicorn')

  managed_template "/data/nginx/servers/#{app}.conf" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    if use_passenger
      source "passenger.conf.erb"
    else
      source "server.conf.erb"
    end

    variables({
      :application => node[:applications][app],
      :unicorn   => unicorn,
      :app_name   => app,
      :app_type => data[:type],
      :mongrel_base_port => mongrel_base_port,
      :mongrel_instance_count => mongrel_instance_count,
      :http_bind_port => node[:applications][app][:http_bind_port],
      :https_bind_port => node[:applications][app][:https_bind_port],
      :server_names => data[:vhosts].first[:name].empty? ? [] : [data[:vhosts].first[:name]],
      :fcgi_pass_port => fcgi_service[:fcgi_pass_port],
      :fcgi_mem_limit => fcgi_service[:fcgi_mem_limit],
      :fcgi_instance_count => fcgi_service[:fcgi_instance_count],
    }.merge(node[:members] ? {:http_bind_port => 81} : {}))
    notifies :run, resources(:execute => "restart-nginx"), :delayed
  end

  # if there is an ssl vhost
  if data[:vhosts][1]

    template "/data/nginx/ssl/#{app}.key" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0644
      source "sslkey.erb"
      variables(
        :key => data[:vhosts][1][:key]
      )
      backup 0
      notifies :run, resources(:execute => "restart-nginx"), :delayed
      end

    template "/data/nginx/ssl/#{app}.crt" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0644
      source "sslcrt.erb"
      variables(
        :crt => data[:vhosts][1][:crt],
        :chain => data[:vhosts][1][:chain]
      )
      backup 0
      notifies :run, resources(:execute => "restart-nginx"), :delayed
      end

    managed_template "/data/nginx/servers/#{app}.ssl.conf" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0644
      if use_passenger
        source "passenger.ssl.conf.erb"
      else
        source "ssl.conf.erb"
      end
      variables({
        :unicorn   => unicorn,
        :application => node[:applications][app],
        :app_name   => app,
        :app_type => data[:type],
        :mongrel_base_port => mongrel_base_port,
        :mongrel_instance_count => mongrel_instance_count,
        :http_bind_port => node[:applications][app][:http_bind_port],
        :https_bind_port => node[:applications][app][:https_bind_port],
        :server_names =>  data[:vhosts][1][:name].empty? ? [] : [data[:vhosts][1][:name]],
        :fcgi_pass_port => fcgi_service[:fcgi_pass_port],
        :fcgi_mem_limit => fcgi_service[:fcgi_mem_limit],
        :fcgi_instance_count => fcgi_service[:fcgi_instance_count],
      }.merge(node[:members] ? {:https_bind_port => 444} : {}))
      notifies :run, resources(:execute => "restart-nginx"), :delayed
    end

  else
    execute "ensure-no-old-ssl-vhosts-for-#{app}" do
      command %Q{
        rm -f /data/nginx/servers/#{app}.ssl.conf;true
      }
    end
  end
  execute "ensure-nginx-is-running" do
    command %Q{
      /etc/init.d/nginx start
    }
    not_if "/etc/init.d/nginx status"
  end
end
