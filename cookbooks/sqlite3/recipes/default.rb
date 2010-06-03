#
# Cookbook Name:: sqlite3
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

if_app_needs_recipe("sqlite3") do |app,data,index|
  
  gem_package "sqlite3-ruby" do
    action :install
  end

end