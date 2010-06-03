postgres_version = '8.3'
postgres_root    = '/var/lib/postgresql'

ey_cloud_report "postgress install" do
  message "processing postgresql #{postgres_version}"
end

require_recipe 'postgres::server_setup'
require_recipe 'postgres::server_configure'

runlevel "postgresql-#{postgres_version}" do
  action :add
end

execute "start-postgres" do
  command "/etc/init.d/postgresql-#{postgres_version} restart"
  action :run
  not_if "/etc/init.d/postgresql-#{postgres_version} status | grep -q start"
end

user = node[:users].first

psql "create-db-user-#{user[:username]}" do
  sql "create user #{user[:username]} with encrypted password '#{user[:password]}'"
  sql_not_if :sql => 'SELECT * FROM pg_roles',
             :assert => "grep #{user[:username]}"
end

node[:applications].each do |app_name,data|
  createdb "#{app_name}_#{node[:environment][:framework_env]}" do
    owner user[:username]
  end
end

require_recipe 'ey-backup::postgres'
