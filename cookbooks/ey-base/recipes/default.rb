#
# Cookbook Name:: ey-base
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute

require 'pp'
Chef::Log.info(ENV.pretty_inspect)

require_recipe 'ruby'

if node[:quick]
  case node[:instance_role]
  when 'app', 'app_master'
    require_recipe 'haproxy::quick'
    require_recipe 'memcached::quick'
    require_recipe 'cron'
  end
else
  require_recipe "ec2" if ['solo', 'app', 'util', 'app_master'].include?(node[:instance_role])
  require_recipe "ey-dynamic::user"

  execute "emerge-sync" do
    command "emerge --sync"
  end

  bash "make-swap" do
    # Make a Linux swap partition that is twice the amount of memory
    # on the high-memory instance (2 x 15GB = 30GB). We make this on
    # /dev/sdc as that device is guaranteed to exist on all 64-bit
    # instances.
    code <<-EOH
      echo "unit: sectors\n/dev/sdc1 : start=63, size=62926542, Id=82" | sfdisk /dev/sdc
      mkswap /dev/sdc1
      swapon /dev/sdc1
      echo "/dev/sdc1 swap swap sw 0 0" >> /etc/fstab
    EOH
    only_if { node[:kernel][:machine] == 'x86_64' and node[:memory][:swap][:total] == '0kB' }
  end

  directory "/data" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
  end

  directory "/data/homedirs" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
  end

  node[:applications].each_key do |app|
    directory "/data/#{app}" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0755
    end
  end

  directory "/var/log/engineyard" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
  end

  directory "/var/cache/engineyard" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0755
  end

  %w{/engineyard /engineyard/bin}.each do |dir|
    directory dir do
      owner "root"
      group "root"
      mode 0755
    end
  end

  remote_file '/etc/security/limits.conf' do
    owner 'root'
    group 'root'
    mode 0644
    source 'limits.conf'
  end

  # the ulimit call MUST remain before the sshd restart for ulimit settings to stick
  execute "restart-sshd-with-good-ulimits" do
    command %Q{
      ulimit -n 65535;
      /etc/init.d/sshd restart
    }
  end

  execute "start-atd" do
    command %Q{
      /etc/init.d/atd restart
    }
    not_if "/etc/init.d/atd status"
  end

  # handle fubar'd gem caches by nuking them
  directory "/root/.gem" do
    action :delete
    recursive true
  end

  # Remove gems that were installed on the system ruby in previous chef runs.
  # They are now installed in the ey_resin isolated ruby.
  gem_package "ey-flex" do
    action :remove
  end

  gem_package "ey_enzyme" do
    action :remove
  end

  gem_package "ey_cloud_server" do
    action :remove
  end

  gem_package "chef" do
    action :remove
  end

  gem_package "chef-deploy" do
    action :remove
  end

  # all roles get these recipes
  require_recipe "ey-bin"
  require_recipe "framework_env"
  require_recipe "chef-custom"
  require_recipe "sudo"
  require_recipe "ssh_keys"
  require_recipe "monit"
  require_recipe "ssmtp"
  require_recipe "redis::config"

  def mongrel?
    node[:environment][:stack] == "nginx_mongrel"
  end

  def passenger?
    node[:environment][:stack] == "nginx_passenger"
  end

  def unicorn?
    node[:environment][:stack] == "nginx_unicorn"
  end

  case node[:instance_role]
  when 'solo'
    require_recipe "ey-dynamic::packages"
    require_recipe "ey-dynamic::rubygems"
    require_recipe "ey-application"
    require_recipe "nginx"
    require_recipe "deploy-keys"
    require_recipe "mysql"
    require_recipe "mysql::master"
    require_recipe "redis"
    require_recipe "backups"
    require_recipe "collectd"
    require_recipe "mongrel"   if mongrel?
    require_recipe "unicorn"   if unicorn?
    require_recipe "app-logs"
    require_recipe "memcached"
    require_recipe "thinking_sphinx"
    require_recipe "cron"
    require_recipe "passenger" if passenger?
    require_recipe "deploy"
    require_recipe "deploy::restart"
  when 'app', 'app_master'
    require_recipe "ey-dynamic::packages"
    require_recipe "ey-dynamic::rubygems"
    require_recipe "ey-application"
    require_recipe "nginx"
    require_recipe "deploy-keys"
    require_recipe "backups"
    require_recipe "collectd"
    require_recipe "mongrel"   if mongrel?
    require_recipe "unicorn"   if unicorn?
    require_recipe "app-logs"
    require_recipe "thinking_sphinx"
    require_recipe "memcached"
    require_recipe "cron"
    require_recipe "passenger" if passenger?
    require_recipe "resource_guard"
    require_recipe "deploy"
    require_recipe "deploy::restart"
    require_recipe "haproxy"
  when 'db_master'
    require_recipe "mysql"
    require_recipe "mysql::master"
    require_recipe "mysql::replication"
    require_recipe "redis"
    require_recipe "backups"
    require_recipe "collectd"
    require_recipe "cron"
  when 'db_slave'
    require_recipe "mysql"
    require_recipe "mysql::slave"
    require_recipe "backups"
    require_recipe "collectd"
  when 'util'
    require_recipe "ey-dynamic::packages"
    require_recipe "ey-dynamic::rubygems"
    require_recipe "backups"
    require_recipe "ey-application"
    require_recipe "app-logs"
    require_recipe "deploy-keys"
    require_recipe "collectd"
    require_recipe "cron"
    require_recipe "deploy"
  end
end
