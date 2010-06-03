if (`grep /db /etc/fstab` == "")
  Chef::Log.info("Mysql EBS devices being formatted")

  ey_cloud_report "mysql ebs" do
    message "processing /db EBS"
  end

  while 1
    if File.exists?("/dev/sdz2")
      directory "/db" do
        owner "mysql"
        group "mysql"
        mode 0755
        recursive true
      end
    
       bash "format-db-ebs" do
         code "mkfs.ext3 -j -F /dev/sdz2"
         not_if "e2label /dev/sdz2"
       end
     
       mount "/db" do
         device "/dev/sdz2"
         fstype "ext3"
       end
     
       bash "grow-db-ebs" do
         code "resize2fs /dev/sdz2"
       end

      break
    end 
    Chef::Log.info("EBS device /dev/sdz2 not available yet...")
    sleep 5
  end
end

ey_cloud_report "mysql" do
  message "processing mysql"
end

directory "/db/mysql/log" do
  owner "mysql"
  group "mysql"
  mode 0755
  recursive true
end

directory "/db/mysql" do
  owner "mysql"
  group "mysql"
  mode 0755
  recursive true
end

execute "do-init-mysql" do
  command %Q{
    mysql_install_db
  }
  not_if { File.directory?('/db/mysql/mysql')  }
end

execute "start-mysql" do
  sleeptime = 15      # check mysql's status every 15 seconds
  sleeplimit = 7200   # give mysql 2 hours to start (for big innodb_log_buffer files)

  command "/usr/local/ey_resin/bin/mysql_start --password #{node.engineyard.environment.ssh_password} --check #{sleeptime} --timeout #{sleeplimit}"

  not_if "/etc/init.d/mysql status"
end

execute "set-root-mysql-pass" do
  command %Q{
    /usr/bin/mysqladmin -u root password '#{node[:owner_pass]}'; true
  }
end

require_recipe "mysql::cleanup"

node.ey_apps.each do |app|

  dbhost = (node[:db_host] == 'localhost' ? 'localhost' : '%')
  
  template "/tmp/create.#{app['name']}.sql" do
    owner 'root'
    group 'root'
    mode 0644
    source "create.sql.erb"
    variables({
      :dbuser => node[:owner_name], 
      :dbpass => node[:owner_pass],
      :dbname => app["database_name"],
      :dbhost => dbhost,
    })
  end

  execute "remove-database-file-for-#{app['name']}" do
    command %Q{
      rm /tmp/create.#{app['name']}.sql
    }
    action :nothing
  end

  execute "create-database-for-#{app['name']}" do
    command %Q{
      mysql -u root -p'#{node[:owner_pass]}' < /tmp/create.#{app['name']}.sql
    }
    notifies(:run, resources(:execute => "remove-database-file-for-#{app['name']}"))
  end 
end

require_recipe "ey-backup::mysql"
