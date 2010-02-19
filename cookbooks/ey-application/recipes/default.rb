#
# Cookbook Name:: ey-application
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#


node[:applications].each do |app, data|
  
  cap_directories = [
    "/data/#{app}/shared",
    "/data/#{app}/shared/config",
    "/data/#{app}/shared/pids",
    "/data/#{app}/shared/system",
    "/data/#{app}/releases"
  ]
  
  cap_directories.each do |dir|
    directory dir do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0755
    end
  end
  
  managed_template "/data/#{app}/shared/config/database.yml" do
    owner node[:owner_name]
    group node[:owner_name]
    mode 0655
    source "database.yml.erb"
    variables({
      :dbuser => node[:owner_name], 
      :dbpass => node[:owner_pass],
      :dbname => "#{app}_#{@node[:environment][:framework_env]}",
      :dbhost => node[:db_host],
      :slaves => node[:db_slaves]
    })
  end

end

(node[:removed_applications]||[]).each do |app|
  execute "remove-data-dir-for-#{app}" do
    command %Q{
      rm -rf /data/#{app}
    }
  end
end
