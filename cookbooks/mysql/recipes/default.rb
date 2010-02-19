#
# Cookbook Name:: mysql
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute

require 'open-uri'
require 'ipaddr'

innodb_buff = calc_innodb_buffer_pool()

# these are both 32-bit unique values, so why not?
private_ip = open('http://169.254.169.254/1.0/meta-data/local-ipv4').read
slave_server_id = IPAddr.new(private_ip).to_i

managed_template "/etc/mysql/my.cnf" do
  owner 'root'
  group 'root'
  mode 0644
  source "my.conf.erb"
  variables({
    :datadir => '/db/mysql',
    :logbase => '/db/mysql/log/',
    :innodb_buff => innodb_buff,
    :replication_master => node[:instance_role] == 'db_master',
    :replication_slave  => node[:instance_role] == 'db_slave',
    :slave_server_id    => slave_server_id,
  })
end

directory "/mnt/mysql/tmp" do
  owner "mysql"
  group "mysql"
  mode 0755
  recursive true
end

remote_file '/etc/conf.d/mysql' do
  owner 'root'
  group 'root'
  mode 0644
  source 'conf.d-mysql'
end

bash "add-db-to-fstab" do
  code "echo '/dev/sdz2 /db ext3 noatime 0 0' >> /etc/fstab"
  not_if "grep /db /etc/fstab"
end
