postgres_version = '8.3'
postgres_root    = '/var/lib/postgresql'

execute "remove kernel.shmmax from sysctl" do
  command "grep -v kernel.shmmax /etc/sysctl.conf >> /tmp/sysctl.conf"
  only_if { "grep kernel.shmmax=#{@node[:total_memory]} /etc/sysctl.conf" } 
end

execute "update-sysctl.conf" do
  command "echo kernel.shmmax=#{@node[:total_memory]} >> /tmp/sysctl.conf && cp /tmp/sysctl.conf /etc/sysctl.conf && sysctl -p && rm /tmp/sysctl.conf"
  action :nothing

  subscribes :run, resources(:execute => 'remove kernel.shmmax from sysctl'), :immediately
end

directory '/db/postgresql' do
  owner 'postgres'
  group 'postgres'
  mode  '0755'
  action :create
  recursive true
end

directory postgres_root do
  action :nothing
  recursive true

  subscribes :delete, resources(:directory => '/db/postgresql'), :immediately
end

link "setup-postgresq-db-my-symlink" do
  to '/db/postgresql'
  target_file postgres_root
end

execute "init-postgres" do
  command "initdb -D #{postgres_root}/#{postgres_version}/data --encoding=UTF8 --locale=en_US.UTF-8"
  action :run
  user 'postgres'
  only_if "[ ! -d #{postgres_root}/#{postgres_version}/data ]"
end
