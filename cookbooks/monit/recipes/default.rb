#
# Cookbook Name:: monit
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#


ey_cloud_report "monit" do
  message "processing monit"
end

template "/etc/monitrc" do
  owner "root"
  group "root"
  mode 0700
  source 'monitrc.erb'
  action :create
end

bash "migrate-monit.d-dir" do
  code %Q{
    mv /etc/monit.d /data/
    ln -nfs /data/monit.d /etc/monit.d
  }

  not_if 'file /etc/monit.d | grep "symbolic link"'
end

directory "/data/monit.d" do
  owner "root"
  group "root"
  mode 0755
end

template "/etc/monit.d/alerts.monitrc" do
  owner "root"
  group "root"
  mode 0700
  source 'alerts.monitrc.erb'
  action :create_if_missing
end

bash "remove monit from gentoo rc" do
  code <<-EOH
rc-update del monit default
/etc/init.d/monit stop
EOH
  only_if 'rc-status default | grep monit'
end

template "/usr/local/bin/monit" do
  owner "root"
  group "root"
  mode 0700
  source 'monit.erb'
  variables({
      :nofile => 16384
  })
  action :create_if_missing
end

bash "replace /usr/bin/monit with /usr/local/bin/monit" do
  code <<-EOH
sed -i -e 's#/usr/bin/monit#/usr/local/bin/monit#g' /etc/inittab
telinit q
EOH
  only_if "grep '/usr/bin/monit' /etc/inittab"
end

bash "add monit to inittab" do
  code <<-EOH
echo "# for monit" >> /etc/inittab && echo "mo:345:respawn:/usr/local/bin/monit -Ic /etc/monitrc" >> /etc/inittab && echo "m0:06:wait:/usr/local/bin/monit -Ic /etc/monitrc stop all" >> /etc/inittab
touch /etc/monit.d/ey.monitrc
telinit q
EOH
  not_if "grep monit /etc/inittab"
end

execute "restart-monit" do
  apps = node[:applications].map{|app, data| data[:type] }
  cmd = []
  apps.each do |app|
    case app
    when 'rails'
      cmd << "pkill -9 mongrel_rails"
    when 'rack'
      cmd << "pkill -9 rackup"
    when 'merb'
      cmd << "ps axx | grep merb | grep -v grep| cut -c1-6| xargs kill -9"
    end
  end
  cmd.uniq!
  command %Q{ #{cmd.join(' && ')} || [[ $? == 1 ]]}
  command %Q{ pkill -9 monit || [[ $? == 1 ]]}
  action :nothing
end

