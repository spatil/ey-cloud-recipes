require 'dbi'

class ResourceGuard
  def self.ensure_mysql_running(db_host, password)
    DBI.connect("DBI:Mysql:engineyard:#{db_host}", 'root', password)
  rescue DBI::DatabaseError => e
    Chef::Log.info("DataBase not available yet, retrying")
    `echo #{e.message} >> /root/db.log`
    sleep 3
    retry
  end
end


