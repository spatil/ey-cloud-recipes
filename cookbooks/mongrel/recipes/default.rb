#
# Cookbook Name:: mongrel
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

if any_app_needs_recipe?('mongrel')

  ey_cloud_report "mongrel" do
    message "processing mongrel"
  end
  
  %w{fastthread mongrel mongrel_cluster}.each do |gem|
    gem_package gem do
      action :install
    end
  end

  directory "/var/log/engineyard/mongrel" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
  end

  directory "/var/run/mongrel" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
  end

  logrotate "mongrel" do
    files "/var/log/engineyard/mongrel/*/*.log"
    copy_then_truncate true
  end

  execute "cleanup monit.d dir" do
    command "rm /etc/monit.d/mongrel*.monitrc
             rm /etc/monit.d/mongrel_merb*.monitrc
             rm /etc/monit.d/mongrel_rack*.monitrc; true"
  end
  
end
  
if_app_needs_recipe("mongrel") do |app,data,index|
  
  directory "/var/log/engineyard/mongrel/#{app}" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
  end
  
  link "/data/#{app}/shared/log" do
    to "/var/log/engineyard/mongrel/#{app}" 
  end
  
  directory "/var/run/mongrel/#{app}" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
  end

  mongrel_service = find_app_service(app, "mongrel")
  mongrel_base_port = (mongrel_service[:mongrel_base_port].to_i + (index * 1000))
  mongrel_instance_count = (get_mongrel_count / node[:applications].size)


  case data[:type]
  when "rails"
    monitrc("mongrel", :mongrel_base_port => mongrel_base_port,
                       :mongrel_instance_count => mongrel_instance_count,
                       :mongrel_mem_limit => mongrel_service[:mongrel_mem_limit],
                       :app_name => app,
                       :user => node[:owner_name])                 
  when "merb"
    directory "/var/log/engineyard/merb" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0755
    end
    directory "/var/log/engineyard/merb/#{app}" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0755
    end
    monitrc("mongrel_merb", :mongrel_base_port => mongrel_base_port,
                            :mongrel_instance_count => mongrel_instance_count,
                            :mongrel_mem_limit => mongrel_service[:mongrel_mem_limit],
                            :app_name => app,
                            :user => node[:owner_name])
  when 'rack'
    monitrc("mongrel_rack", :mongrel_base_port => mongrel_base_port,
                            :mongrel_instance_count => mongrel_instance_count,
                            :mongrel_mem_limit => mongrel_service[:mongrel_mem_limit],
                            :app_name => app,
                            :user => node[:owner_name])

    remote_file "/engineyard/bin/rackup_stop" do
      owner "root"
      group "root"
      mode 0777
      source "rackup_stop"
      action :create
    end
  end
  
  template "/data/#{app}/shared/config/mongrel_cluster.yml" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0644
    variables({
      :mongrel_base_port => mongrel_base_port,
      :mongrel_instance_count => mongrel_service[:mongrel_instance_count],
      :app_name => app
    })
    source "mongrel_cluster.yml.erb"
    notifies :run, resources(:execute => "restart-monit")
  end

end

(node[:removed_applications]||[]).each do |app|
  execute "remove-mongrel-logs-for-#{app}" do
    command %Q{
      rm -rf /var/log/engineyard/mongrel/#{app}
    }
  end
end
