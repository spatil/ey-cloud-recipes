template "/tmp/mysql-cleanup.sql" do
  mysql_hostname = node[:ec2][:local_hostname].split(".").first

  owner 'root'
  group 'root'
  mode 0644
  source "cleanup.sql.erb"
  variables({
    :dbpass => node[:owner_pass],
    :user_hosts => [
      ['',    'localhost'],
      ['',     mysql_hostname],
      ['root','127.0.0.1'],
      ['root', mysql_hostname],
      ['root', '%'],
    ]
  })
end

execute "remove-database-file-for-mysql-cleanup" do
  command %Q{
    rm /tmp/mysql-cleanup.sql
  }
  action :nothing
end

execute "create-database-for-mysql-cleanup" do
  command %Q{
    mysql -u root -p'#{node[:owner_pass]}' < /tmp/mysql-cleanup.sql
  }
  notifies(:run, resources(:execute => "remove-database-file-for-mysql-cleanup"))
end
