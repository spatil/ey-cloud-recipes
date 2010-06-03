#
# Cookbook Name:: binlog-rotation
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

directory "/root/eydba" do
  owner 'root'
  mode '0755'
end

directory "/root/eydba/binary_logs" do
  owner 'root'
  mode '0755'
end

remote_file "/root/eydba/binary_logs/binary_log_purge.rb" do
  owner 'root'
  mode '0755'
  source "binary_log_purge.rb"
end

# we need to turn down the number of files kept from the default of 5;
# the files are 1GB in size and if we keep 5, DB masters using the
# default volume size will get filled up.
#
# setting it to 2 allows for 2 full files + 1 partial, so a max of 3GB
# used by binlogs.
remote_file "/etc/.binlogpurge.yml" do
  owner 'root'
  mode '0644'
  source "binlogpurge.yml"
end

cron "binary_log_purge" do
  minute  '0'
  hour    '*/4'
  day     '*'
  month   '*'
  weekday '*'
  command '/root/eydba/binary_logs/binary_log_purge.rb -q'
end
