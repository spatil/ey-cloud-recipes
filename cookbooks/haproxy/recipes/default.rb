  #
  # Cookbook Name:: haproxy
  # Recipe:: default
  #
  # Copyright 2009, Engine Yard, Inc.
  #
  # All rights reserved - Do Not Redistribute
  #
if node[:members]
  
  ey_cloud_report "haproxy" do
    message 'processing haproxy'
  end
  
  package "net-proxy/haproxy" do
    action :install
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
  
  execute "add-haproxy-to-init" do
    command "rc-update add haproxy default"
    not_if "rc-status | grep haproxy"
  end
  
  command = node[:quick] ? 'reload' : 'restart'
  
  execute "restart-haproxy" do
    command "/etc/init.d/haproxy #{command}"
    action :run
  end
  
  bash "add-ey-monitor-to-inittab" do
    code <<-EOH
  echo "# for ey-monitor" >> /etc/inittab && echo "ey:345:respawn:/usr/bin/ey-monitor >> /root/ey-monitor.log 2>&1" >> /etc/inittab
  EOH
    not_if "grep ey-monitor /etc/inittab"
  end

end
