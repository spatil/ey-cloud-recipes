#
# Cookbook Name:: haproxy
# Recipe:: quick
#
# Copyright 2009, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

if node[:members]

  ey_cloud_report "haproxy" do
    message 'processing haproxy'
  end

  managed_template "/etc/haproxy.cfg" do
    owner 'root'
    group 'root'
    mode 0644
    source "haproxy.cfg.erb"
    variables({
      :backends => node[:members],
      :haproxy_user => node[:haproxy][:username],
      :haproxy_pass => node[:haproxy][:password]
    })
  end

  execute "reload-haproxy" do
    command "/etc/init.d/haproxy reload"
    action :run
  end
end
