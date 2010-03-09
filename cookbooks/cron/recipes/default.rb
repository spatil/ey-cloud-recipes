#
# Cookbook Name:: cron
# Recipe:: default
#
# Copyright 2009, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

unless node[:crons].empty?
  ey_cloud_report "cron" do
    message "processing crontabs"
  end
end

execute "clearing old crons" do
  command "crontab -r; crontab -r -u #{node[:owner_name]}; true"
end

execute "add resin PATH to cron" do
  command %{echo "PATH=/bin:/usr/bin:/usr/local/ey_resin/bin" > /tmp/newcronforresinpath; crontab /tmp/newcronforresinpath && rm /tmp/newcronforresinpath}
  not_if 'crontab -l | grep -q "^PATH"'
end

cron_hour = if node[:backup_interval].to_s == '24'
              "1"    # 0100 Pacific, per support's request
              # NB: Instances run in the Pacific (Los Angeles) timezone
            elsif node[:backup_interval]
              "*/#{node[:backup_interval]}"
            else
              "1"
            end

if ['solo', 'db_master'].include?(node[:instance_role])
  cron "eybackup" do
    minute   '10'
    hour     cron_hour
    day      '*'
    month    '*'
    weekday  '*'
    command  "eybackup"
    not_if { node[:backup_window].to_s == '0' }
  end  
end

unless 'app' == node[:instance_role]
  cron "ey-snapshots" do
    minute   '0'
    hour     cron_hour
    day      '*'
    month    '*'
    weekday  '*'
    command  "ey-snapshots --snapshot"
    not_if { node[:backup_window].to_s == '0' }
  end
end

directory "/var/spool/cron" do
  group "crontab"
end

if ['solo', 'app_master'].include?(node[:instance_role])
  (node[:crons]||[]).each do |c|
    cron c[:name] do
      minute   c[:minute]
      hour     c[:hour]
      day      c[:day]
      month    c[:month]
      weekday  c[:weekday]
      command  c[:command]
      user     c[:user]
    end
  end
end
