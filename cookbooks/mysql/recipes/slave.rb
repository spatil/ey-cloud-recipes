wait_for_master_db node[:db_host] do
  password node[:owner_pass]
end

mysql_slave node[:db_host] do
  password node[:owner_pass]
  creds = YAML.load_file("/etc/.ey-cloud.yml")
  aws_secret_key creds[:aws_secret_key]
  aws_secret_id creds[:aws_secret_id]
end

def self.mysql_slave_is_slavey?
  begin
    dbh = DBI.connect("DBI:Mysql:mysql:localhost", 'root', node[:owner_pass])
    !dbh.select_all("show slave status").empty?
  rescue
    false
  end
end

# Only run the mysql_slave recipes if it isn't already a slave
# Huge hack until http://tickets.opscode.com/browse/CHEF-516 is fixed
updating = false
collection.each do |r|
  updating = true if r.to_s == "execute[start-of-mysql-slave]"
  updating = false if r.to_s == "execute[stop-of-mysql-slave]"
  if updating && !r.not_if
    Chef::Log.info("#{r.to_s} of #{params[:only_if].inspect}")
    r.not_if do
      mysql_slave_is_slavey?
    end
  end
end
