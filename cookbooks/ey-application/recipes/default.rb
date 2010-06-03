#
# Cookbook Name:: ey-application
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#


node.engineyard.apps.each do |app|
  app_directory app.name do
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
  end

  managed_template "/data/#{app.name}/shared/config/database.yml" do
    # adapter: postgres   => datamapper
    # adapter: postgresql => active record
    dbtype = case node.engineyard.environment.db_stack
             when DNApi::DbStack::Mysql     then 'mysql'
             when DNApi::DbStack::Postgres  then 'postgresql'
             end

    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode 0655
    source "database.yml.erb"
    variables({
      :dbuser => node.engineyard.environment.ssh_username,
      :dbpass => node.engineyard.environment.ssh_password,
      :dbname => app.database_name,
      :dbhost => node.engineyard.environment.db_host,
      :dbtype => dbtype,
      :slaves => node.engineyard.environment.db_slaves_hostnames
    })
  end
end

(node[:removed_applications]||[]).each do |app|
  app_directory app do
    action :delete
  end
end
