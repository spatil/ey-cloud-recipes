template "/etc/.mysql.backups.yml" do
  owner 'root'
  group 'root'
  mode 0600
  source "backups.yml.erb"
  variables({
    :dbuser => 'root',
    :dbpass => node[:owner_pass],
    :keep   => node[:backup_window] || 14,
    :id     => node[:aws_secret_id],
    :key    => node[:aws_secret_key],
    :env    => node[:environment][:name],
    :databases => node.engineyard.apps.map {|app| app.database_name }
  })
end

# TODO: clean this shit up
if node.engineyard.environment.mysql_backup_cron && (node.engineyard.solo? || node.engineyard.role.to_s == 'db_master')
  backup_cron "mysql" do
    cron node.engineyard.environment.mysql_backup_cron
  end
end
