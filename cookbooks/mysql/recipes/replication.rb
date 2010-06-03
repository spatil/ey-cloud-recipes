template "/tmp/root_perms.sql" do
  owner 'root'
  group 'root'
  mode 0644
  source "lock_tables.sql.erb"
  variables({
    :dbpass => node[:owner_pass],
    :dbname => "engineyard",
    :locktable => 'locks',
    :master => node[:master_app_server][:private_dns_name]
  })
end

execute "remove-lock-sql-file" do
  command %Q{
    rm /tmp/root_perms.sql
  }
  action :nothing
end

execute "create-database-for-locks" do
  command %Q{
    mysql -u root -p'#{node[:owner_pass]}' < /tmp/root_perms.sql
  }
  notifies(:run, resources(:execute => "remove-lock-sql-file"))
end
