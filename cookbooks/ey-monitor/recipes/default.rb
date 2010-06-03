file "/usr/bin/ey-monitor" do
  action :delete
  only_if "test -e /usr/bin/ey-monitor"
end

link "/usr/bin/ey-monitor" do
  to "/usr/local/ey_resin/bin/stonith-cron"
end

bash "add-ey-monitor-to-inittab" do
  code <<-EOH
echo "# for ey-monitor" >> /etc/inittab && echo "ey:345:respawn:/usr/bin/ey-monitor >> /root/ey-monitor.log 2>&1" >> /etc/inittab
EOH
  not_if "grep ey-monitor /etc/inittab"
end

template "/etc/stonith.yml" do
  owner node[:owner_name]
  group node[:owner_name]
  mode 0644
  source "stonith.yml.erb"
  variables({
    :endpoint_uri => node.engineyard.environment.stonith_endpoint,
    :endpoint_token => node.engineyard.awsm_token,
    :monitor_host => node.engineyard.environment.app_master.private_hostname,
    :redis_host => node[:db_host],
    :redis_port => 6379,
    :aws_secret_id => node.engineyard.environment.aws_secret_id,
    :aws_secret_key => node.engineyard.environment.aws_secret_key,
    :meta_data_hostname => node.engineyard.private_hostname,
    :meta_data_id => node.engineyard.id,
  })
end

bash "let init restart ey-monitor" do
  code "pkill -f ey-monitor || true"
end
