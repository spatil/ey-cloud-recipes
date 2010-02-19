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

script "restart-mysql" do
  code %Q{
    count = 0
    loop {
      if system('/etc/init.d/mysql restart')
        `echo "Mysql restarted sucessfully" >> /root/chef-mysql.log`
        exit 0
      else
        `echo "Failed to restart, zapping" >> /root/chef-mysql.log`
        begin
          pidfile = '/var/run/mysqld/mysqld.pid'
          if File.exists?(pidfile)
            File.open('/var/run/mysqld/mysqld.pid', 'r') do |f|
              pid = f.read.to_i
              Process.kill("TERM", pid)

              mysqld_is_dead = false
              started_at = Time.now
              # /etc/init.d/mysql has 120 as STOPTIMEOUT, so we should
              # wait at least that long
              until mysqld_is_dead || ((Time.now - started_at) > 120)
                begin
                  Process.kill(0, pid)
                  sleep 1
                rescue Errno::ESRCH      # no such process
                  mysqld_is_dead = true
                end
              end

            end
          end
        rescue Exception => e
          File.open('/root/chef-mysql.log', 'a') do |f|
            f.write("Blew up: \n")
            f.write(e.message)
            f.write("\n")
            f.write(e.backtrace.join("\t\n"))
          end
        end
        system('/etc/init.d/mysql zap')
      end
      count += 1
      exit(1) if count > 10
      sleep 1
    }
    `echo "Fell out after 10 tries, moving on" >> /root/chef-mysql.log`
  }
  interpreter "ruby"
  action :run
  not_if "/etc/init.d/mysql status"
end

execute "set-root-mysql-pass" do
  command %Q{
    /usr/bin/mysqladmin -u root password '#{node[:owner_pass]}'; true
  }
end

require_recipe "mysql::cleanup"

node[:applications].each_key do |app|

  dbhost = (node[:db_host] == 'localhost' ? 'localhost' : '%')
  
  template "/tmp/create.#{app}.sql" do
    owner 'root'
    group 'root'
    mode 0644
    source "create.sql.erb"
    variables({
      :dbuser => node[:owner_name], 
      :dbpass => node[:owner_pass],
      :dbname => "#{app}_#{@node[:environment][:framework_env]}",
      :dbhost => dbhost
    })
  end

  execute "remove-database-file-for-#{app}" do
    command %Q{
      rm /tmp/create.#{app}.sql
    }
    action :nothing
  end

  execute "create-database-for-#{app}" do
    command %Q{
      mysql -u root -p'#{node[:owner_pass]}' < /tmp/create.#{app}.sql
    }
    notifies(:run, resources(:execute => "remove-database-file-for-#{app}"))
  end 
end
