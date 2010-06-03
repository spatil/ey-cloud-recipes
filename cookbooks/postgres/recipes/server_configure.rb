postgres_version = '8.3'
postgres_root    = '/var/lib/postgresql'

template "#{postgres_root}/#{postgres_version}/data/postgresql.conf" do
  source "postgresql.conf.erb"
  owner "postgres"
  group "root"
  mode 0600

  variables(
    :sysctl_shared_buffers => node[:sysctl_shared_buffers],
    :shared_buffers => node[:shared_buffers],
    :max_fsm_pages => node[:max_fsm_pages],
    :max_fsm_relations => node[:max_fsm_relations],
    :maintenance_work_mem => node[:maintenance_work_mem],
    :work_mem => node[:work_mem],
    :max_stack_depth => node[:max_stack_depth],
    :effective_cache_size => node[:effective_cache_size],
    :default_statistics_target => node[:default_statistics_target],
    :logging_collector => node[:logging_collector],
    :log_rotation_age => node[:log_rotation_age],
    :log_rotation_size => node[:log_rotation_size],
    :checkpoint_timeout => node[:checkpoint_timeout],
    :checkpoint_segments => node[:checkpoint_segments],
    :wal_buffers => node[:wal_buffers],
    :wal_writer_delay => node[:wal_writer_delay],
    :postgres_root => postgres_root,
    :postgres_version => postgres_version
  )
end

file "#{postgres_root}/#{postgres_version}/custom.conf" do
  action :create
  owner node[:owner_name]
  group node[:owner_name]
  mode 0644
  not_if { FileTest.exists?("#{postgres_root}/#{postgres_version}/custom.conf") }
end

template "#{postgres_root}/#{postgres_version}/data/pg_hba.conf" do
  owner 'postgres'
  group 'root'
  mode 0600
  source "pg_hba.conf.erb"
  variables({
    :dbuser => node[:users].first[:username],
    :dbpass => node[:users].first[:password]
  })
end

execute "postgresql-restart" do
  command "/etc/init.d/postgresql-#{postgres_version} restart"
  action :nothing

  subscribes :run, resources(
    :template => "#{postgres_root}/#{postgres_version}/data/postgresql.conf",
    :file     => "#{postgres_root}/#{postgres_version}/custom.conf",
    :template => "#{postgres_root}/#{postgres_version}/data/pg_hba.conf")

  only_if "/etc/init.d/postgresql-#{postgres_version} status"
end
