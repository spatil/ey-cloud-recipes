#
# Cookbook Name:: ey-agent
# Recipe:: default
#
# Copyright 2009, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

gem_package "nanite" do 
  source "http://gems.engineyard.com"
  action :install
end  

execute "install-ey-agent" do
  command %Q{
    mkdir -p /data/ey-agent &&
    cd /data/ey-agent &&
    curl https://ey-ec2.s3.amazonaws.com/ey-agent-staging.tgz -O &&
    tar xvzf ey-agent-staging.tgz
  }
  creates "/data/ey-agent"
end

execute "run-ey-agent" do
  command %Q{
    cd /data/ey-agent &&
    nanite -d
  }
  not_if "pgrep nanite"
end  