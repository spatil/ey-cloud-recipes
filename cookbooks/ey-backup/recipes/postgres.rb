template "/etc/.postgresql.backups.yml" do
  owner 'root'
  group 'root'
  mode 0600
  source "backups.yml.erb"
  variables({
    :dbuser => node[:users].first[:username],
    :dbpass => node[:users].first[:password],
    :keep   => node[:backup_window] || 14,
    :id     => node[:aws_secret_id],
    :key    => node[:aws_secret_key],
    :env    => node[:environment][:name],
    :databases => node.engineyard.apps.map {|app| app.database_name }
  })
end

if node.engineyard.environment.postgres_backup_cron
  backup_cron "postgresql" do
    cron node.engineyard.environment.postgres_backup_cron
  end
end
