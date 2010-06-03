#
# Cookbook Name:: passenger
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

if node.engineyard.environment.stack.passenger?
  ey_cloud_report "passenger" do
    message "processing passenger"
  end

  gem_package "passenger" do
    action :install
    version node[:passenger_version]
  end

  node.engineyard.apps.each do |app|
    cron "passenger_monitor_#{app.name}" do
      minute '*'
      hour '*'
      day '*'
      weekday '*'
      month '*'
      command "/engineyard/bin/passenger_monitor #{app.name} -f #{app.type} >/dev/null 2>&1"
    end
  end

  if node.engineyard.environment.stack.apache?
    require_recipe 'passenger::apache'
  end
end
