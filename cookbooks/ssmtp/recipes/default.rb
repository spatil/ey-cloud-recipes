#
# Cookbook Name:: ssmtp
# Recipe:: default
#
# Copyright 2009, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#
# chown #{owner}:#{owner} /etc/ssmtp/ssmtp.conf

execute "fix the permissions" do
  owner = node[:owner_name]
  command %Q{
    chmod +x /usr/sbin/ssmtp
    ln -nfs /data/ssmtp.conf /etc/ssmtp/ssmtp.conf
  }
end
