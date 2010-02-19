#
# Cookbook Name:: ey-bin
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "templates", "default", "*"))].each do |file|
  filename = File.basename(file, ".erb")
  template "/engineyard/bin/#{filename}" do
    owner 'root'
    group 'root'
    mode 0755
    source "#{filename}.erb"
    variables({
      :rails_env => node[:environment][:framework_env]
    })
  end
end
