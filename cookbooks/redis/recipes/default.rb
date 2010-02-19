#
# Cookbook Name:: redis
# Recipe:: default
#
 
package "dev-db/redis" do
  action :install
end

directory "/db/redis" do
  owner 'redis'
  group 'redis'
  mode 0755
  recursive true
end

managed_template "/etc/redis.conf" do
  owner 'root'
  group 'root'
  mode 0644
  source "redis.conf.erb"
  variables({
    :basedir => '/db/redis',
    :logfile => '/db/redis/redis.log',
    :port  => '6379',
    :loglevel => 'notice',
    :timeout => 3000,
    :sharedobjects => 'no'
  })
end

execute "add-redis-to-default-runlevel" do
  command "rc-update add redis default"
  not_if "rc-status | grep redis"
end
 
execute "ensure-redis-is-running" do
  command %Q{
    /etc/init.d/redis start
  }
  not_if "pgrep redis-server"
end
