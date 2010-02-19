#
# Cookbook Name:: ey-dynamic
# Recipe:: packages
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

ey_cloud_report "packages" do
  message "processing unix packages"
end

execute "unmask-couchdb" do
  command %Q{
    echo "dev-db/couchdb ~amd64 ~x86" >> /etc/portage/package.keywords/ec2
  }
  not_if "grep dev-db/couchdb /etc/portage/package.keywords/ec2"
end

node[:packages_to_install].each do |pkg|
  ey_cloud_report "each package" do
    message "processing package: #{pkg[:name]}"
  end
  package pkg[:name] do
    if pkg[:version] && !pkg[:version].empty?
      version pkg[:version]
    end
    action :install
  end
end
