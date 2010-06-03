#
# Cookbook Name:: redis::config
# Recipe:: default
#

template "/etc/redis.yml" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0644
  source "redis.yml.erb"
  variables({
    :host => node[:db_host],
    :port => 6379,
  })
end