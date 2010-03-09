#
# Cookbook Name:: nginx
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

if any_app_needs_recipe?("nginx")

  ey_cloud_report "nginx" do
    message "processing nginx"
  end

  use_passenger = any_app_needs_recipe?('nginx-passenger')


  package "nginx" do
    version '0.6.35-r22'
  end

  if any_app_needs_recipe?('nginx-passenger')
    ey_cloud_report "nginx-passenger" do
      message "processing nginx-passenger"
    end

    remote_file '/usr/bin/ruby-for-passenger' do
      owner 'root'
      group 'root'
      mode 0755
      source 'ruby-for-passenger'
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
  execute "launch-nginx-at-boot" do
    command "rc-update add nginx default"
    action :run
    not_if "rc-status | grep nginx"
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
  end

  managed_template "/data/nginx/common/servers.conf" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    source "common.servers.conf.erb"
  end

  managed_template "/data/nginx/common/fcgi.conf" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    source "common.fcgi.conf.erb"
  end

  file "/data/nginx/servers/default.conf" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
  end



  # this is for when we finally clean up our graphing stuff anf run it under ssl
  #template "/data/nginx/servers/minihttpd.ssl.conf" do
  #  owner node[:owner_name]
  #  group node[:owner_name]
  #  mode 0644
  #  source "minihttpd.ssl.conf.erb"
  #  variables({
  #    :port => '8989',
  #    :minihttpd_port => '8988'
  #  })
  #end
  #
  #execute "generate-self-signed-cert-for-ajaxterm" do
  #  command %Q{
  #    openssl req -x509 -days 365 -newkey rsa:1024 -nodes \
  #      -subj '/CN=ajaxterm' \
  #      -keyout /data/nginx/ssl/minihttpd.key -out /data/nginx/ssl/minihttpd.crt
  #  }
  #  creates "/data/nginx/ssl/minihttpd.key"
  #end

end

(node[:removed_applications]||[]).each do |app|
  execute "remove-old-vhosts-for-#{app}" do
    command %Q{
      rm -rf /data/nginx/servers/#{app}*
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
  end

  managed_template "/data/nginx/servers/#{app}.users" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    source "users.erb"
    variables({
      :application => node[:applications][app]
    })
  end

  managed_template "/data/nginx/servers/#{app}/custom.locations.conf" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    source "custom.locations.conf.erb"
    action :create_if_missing
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
  end

  # if there is an ssl vhost
  if data[:vhosts][1]

    execute "output-ssl-certs" do
      command %Q{
        echo '#{data[:vhosts][1][:key]}' > /data/nginx/ssl/#{app}.key
        echo '#{data[:vhosts][1][:crt]}' > /data/nginx/ssl/#{app}.crt
        echo '#{data[:vhosts][1][:chain]}' >> /data/nginx/ssl/#{app}.crt
      }
      not_if { data[:vhosts][1][:crt].empty? && data[:vhosts][1][:key].empty? }
    end

    execute "generate-self-signed-cert" do
      command %Q{
        openssl req -x509 -days 365 -newkey rsa:1024 -nodes \
          -subj '/CN=#{data[:vhosts][1][:name]}' \
          -keyout /data/nginx/ssl/#{app}.key -out /data/nginx/ssl/#{app}.crt
      }
      creates "/data/nginx/ssl/#{app}.key"
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
    end

  else
    execute "ensure-no-old-ssl-vhosts-for-#{app}" do
      command %Q{
        rm -f /data/nginx/servers/#{app}.ssl.conf;true
      }
    end
  end

end

if any_app_needs_recipe?("nginx")

  execute "restart-nginx" do
    command "/etc/init.d/nginx restart"
    action :run
  end

end
