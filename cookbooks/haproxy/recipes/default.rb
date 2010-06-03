  #
  # Cookbook Name:: haproxy
  # Recipe:: default
  #
  # Copyright 2009, Engine Yard, Inc.
  #
  # All rights reserved - Do Not Redistribute
  #

ey_cloud_report "haproxy" do
  message 'processing haproxy'
end

require_recipe 'haproxy::configure'
require_recipe 'haproxy::install' unless node[:quick]
