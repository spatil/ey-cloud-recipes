#
# Cookbook Name:: resource_guard
# Recipe:: default
#
# Copyright 2009, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

wait_for_master_db node[:db_host] do
  password node[:owner_pass]
end
