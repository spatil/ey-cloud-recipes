require 'tempfile'
require 'dbi'
require 'open-uri'
require 'right_aws'

mysql_slave_default_params = {
  :password => nil,
  :aws_secret_key => nil,
  :aws_secret_id => nil,
  :only_if => false,
}

define :mysql_slave, mysql_slave_default_params do
  master_host = params[:name]
  password = params[:password]
  aws_secret_key = params[:aws_secret_key]
  aws_secret_id = params[:aws_secret_id]

  execute "start-of-mysql-slave" do
    # Used for hack to add only_ifs to these resources
    command "echo"
  end

  ruby_block "clean up half-done install" do
    block do
      system('/etc/init.d/mysql stop')
      system('umount /db')
      FileUtils.rmdir '/db'

      instance_id = open('http://169.254.169.254/1.0/meta-data/instance-id').read
      node[:raws] ||= RightAws::Ec2.new(aws_secret_id, aws_secret_key)
      db_volume_info = node[:raws].describe_volumes.find { |v| v[:aws_instance_id] == instance_id && v[:aws_device] == "/dev/sdz2" }
      if db_volume_info
        volume_id = db_volume_info[:aws_id]

        node[:raws].detach_volume volume_id
        until node[:raws].describe_volumes(volume_id)[0][:aws_status] == 'available'
          sleep 5
        end

        node[:raws].delete_volume volume_id
      end
    end

    # NB: there's already a guard such that we don't run if
    # replication is working. This code should only execute if /db is
    # mounted, but replication is busted, in which case we clean up
    # and start fresh.
    only_if { File.exists?("/db") }
  end

  report_and_run "locking tables on master in preparation for snapshot" do
    run(lambda do
      node[:master_dbi] = DBI.connect("DBI:Mysql:mysql:#{master_host}", 'root', password)
    end)
  end

  ruby_block "flush-tables-on-master" do
    block do
      node[:master_dbi].do("FLUSH TABLES WITH READ LOCK")
    end
  end

  ruby_block 'show-master-status' do
    block do
      node[:show_master_status] = node[:master_dbi].select_all('SHOW MASTER STATUS').flatten
    end
  end

  report_and_run "taking snapshot of database master" do
    run(lambda do
      node[:raws] ||= RightAws::Ec2.new(aws_secret_id, aws_secret_key)
      master_id = node[:raws].describe_instances.detect {|x| x[:dns_name] == master_host}[:aws_instance_id]
      node[:master_db_vol_id] = node[:raws].describe_volumes.detect {|x| x[:aws_instance_id] == master_id && x[:aws_device] == "/dev/sdz2"}[:aws_id]
      node[:snap_id] = node[:raws].create_snapshot(node[:master_db_vol_id])[:aws_id]
    end)
  end

  report_and_run "releasing master database lock" do
    run(lambda do
      node[:master_dbi].do("UNLOCK TABLES")
      node[:master_dbi].disconnect
    end)
  end

  report_and_run "waiting for master snapshot to complete" do
    run(lambda do
      until(node[:raws].describe_snapshots(node[:snap_id]).first[:aws_status] == "completed")
        sleep 5
      end
    end)
  end

  report_and_run "snapshot complete, attaching volume" do
    run(lambda do
      master_volume = node[:raws].describe_volumes(node[:master_db_vol_id]).first
      availability_zone = open('http://169.254.169.254/latest/meta-data/placement/availability-zone').read
      node[:volume_id] = node[:raws].create_volume(node[:snap_id], master_volume[:size], availability_zone)[:aws_id]
    end)
  end

  ruby_block "wait-for-volume" do
    block do
      until(node[:raws].describe_volumes(node[:volume_id]).first[:aws_status] == "available")
        sleep 5
      end
      id = open("http://169.254.169.254/latest/meta-data/instance-id").read
      node[:raws].attach_volume(node[:volume_id], id, "/dev/sdz2")
      until(node[:raws].describe_volumes(node[:volume_id]).first[:aws_status] == "in-use")
        sleep 5
      end
    end
  end

  execute "stop-mysql" do
    command "/etc/init.d/mysql stop"
  end

  directory "/db" do
    owner "mysql"
    group "mysql"
    mode 0755
    recursive true
  end

  mount "/db" do
    fstype "ext3"
    device "/dev/sdz2"
    action :mount
    epic_fail true
  end

  mount "/db" do
    action :enable
  end

  ruby_block "wait-for-db-slave-device" do
    block do
      until system("ls -l /db/mysql")
        sleep 3
        Array(resources(:mount => "/db")).each do |resource|
          resource.run_action(:mount)
        end
      end
    end
  end

  execute "clean-up-master's-bin-logs" do
    command "find /db/mysql/ -name 'master-bin*' -exec rm -f {} \\;"
  end

  execute "start-mysql" do
    command %Q{
      /etc/init.d/mysql start
    }
  end

  ruby_block "setup-slave-database" do
    block do
      dbi = DBI.connect("DBI:Mysql:mysql:localhost", 'root', password)
      command =  "CHANGE MASTER TO"
      command << " MASTER_HOST='#{master_host}',"
      command << " MASTER_USER='replication',"
      command << " MASTER_PASSWORD='#{password}',"
      command << " MASTER_LOG_FILE='#{node[:show_master_status][0]}',"
      command << " MASTER_LOG_POS=#{node[:show_master_status][1]}"
      dbi.do(command)
      dbi.do("start slave")
      dbi.disconnect
    end
  end

  execute "stop-of-mysql-slave" do
    # Used for hack to add only ifs to these resources
    command "echo"
  end

end

