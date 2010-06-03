#
# Cookbook Name:: mysql
# Recipe:: mytop
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute

template "/root/.mytop" do
  owner 'root'
  mode 0600
  variables ({
    :username => node[:owner_name],
    :password => node[:owner_pass],
  })
  source "mytop.erb"
end

